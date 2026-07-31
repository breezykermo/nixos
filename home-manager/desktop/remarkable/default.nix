# ReMarkable related software
{
  config,
  lib,
  machineVars,
  ...
}: {
  imports = [
    ./remouse # FreeCap23 tablet driver for Wayland (pressure + tilt)
  ];

  # This module is imported unconditionally (see home-manager/desktop/default.nix), so
  # gate its config on the homework flag — the only machine with a ReMarkable tablet.
  config = lib.mkIf config.custom.homework {
    # NOTE: rcu must be purchased; link it via:
    #   nix-store --add-fixed sha256 rcu-d2024.001q-source.tar.gz

    home.shellAliases = {
      # reMarkable tablet: run with landscape rotation (USB-C on left)
      # Use -r 1 for 90° CW, -r 2 for 180°, -r 3 for 270° CW
      rmt = "rmTabletDriver --key=/home/${machineVars.userName}/.ssh/${machineVars.remarkableKey} -r 2";
      rmt-portrait = "rmTabletDriver --key=/home/${machineVars.userName}/.ssh/${machineVars.remarkableKey}";
      # Monitor switching. The pen is an absolute device, so it spans all outputs
      # unless bound to one. DP-3 is the default, set declaratively in
      # desktop/hypr/default.nix; these re-bind it at runtime.
      #
      # Hyprland 0.56 dropped the flat `device:<name>:<option>` path for
      # `hyprctl keyword` ("config option ... does not exist"); per-device options
      # are addressed as `device[<name>]:<option>`. The rule is stored and applied
      # when a matching device appears, so these work before `rmt` starts too.
      rm-4k = "hyprctl keyword 'device[remarkabletablet-fakepen]:output' DP-3";
      rm-side = "hyprctl keyword 'device[remarkabletablet-fakepen]:output' DP-1";
      # Discard runtime re-binds and go back to the declared default (DP-3).
      rm-reset = "hyprctl reload";
    };
  };
}
