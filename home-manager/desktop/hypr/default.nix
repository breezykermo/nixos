{
  config,
  pkgs,
  lib,
  theme,
  ...
}: let
  wallpapers = import ../../../wallpapers {inherit pkgs;};

  # Convert hex colors to Hyprland rgba format
  # Using yellow for active border to match tmux, subtle gray for inactive
  activeBorderColor = theme.helpers.toHyprRgba theme.colors.yellow "ff";
  inactiveBorderColor = theme.helpers.toHyprRgba theme.colors.bg3 "aa";
in {
  imports = [
    ./hyprlock.nix
    ./hypridle.nix
  ];

  home.packages = with pkgs; [
    swaybg
    wdisplays
    way-displays
    brightnessctl
  ];

  # Copy FCL wallpaper to home directory
  home.file.".local/share/wallpapers/fcl-widescreen.png" = {
    source = "${wallpapers.fcl-widescreen}/wallpaper.png";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    xwayland.enable = true;
    systemd.variables = ["-all"];
    extraConfig = ''
      ${builtins.readFile ./hypr.conf}

      # Theme-specific overrides
      general {
      	col.active_border = ${activeBorderColor}
      	col.inactive_border = ${inactiveBorderColor}
      }

      ${lib.optionalString config.custom.homework ''
        # OBS scene switching. OBS's own hotkeys only fire while OBS has focus on
        # Wayland, so the switch goes through obs-websocket instead and works
        # whatever window is active. The names must match the scene collection.
        bind = , F1, exec, obs-scene "Screenshare"
        bind = , F2, exec, obs-scene "Camera"

        # ReMarkable tablet (rmTabletDriver, alias `rmt`). The pen is an absolute
        # positioning device, so without an output binding it stretches across every
        # monitor. Pin it to the 4K panel. The name is the uinput device name from
        # remouse/patched/tabletDriver.c ("reMarkableTablet-FakePen"), lowercased.
        # The device only exists while the driver runs; Hyprland applies the rule
        # when it appears, so this can be declared up front.
        device {
          name = remarkabletablet-fakepen
          output = DP-3
        }
      ''}
    '';
  };
}
