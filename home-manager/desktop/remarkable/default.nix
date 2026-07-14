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
      # Monitor switching (note: may not work due to Hyprland tablet limitations)
      rm-laptop = "hyprctl keyword device:remarkabletablet-fakepen:output eDP-1";
      rm-external = "hyprctl keyword device:remarkabletablet-fakepen:output DP-1";
    };
  };
}
