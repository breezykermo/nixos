{ config, lib, pkgs, ... }:

{
  imports = [
    # ./hyprland.nix
    # ./waybar.nix
    # ./mako.nix
    # ./rofi.nix
    # ./alacritty.nix
    # ./zathura.nix
    # ./wezterm.nix
  ];

  home.packages = with pkgs;
  [ # Base
    firefox
    xdg-utils
  ]
  ++ [ # Fonts
    liberation_ttf
  ];

  wayland.windowManager.sway = {
    enable = true;
    modifer = "Mod4";
    output = {
      "DP-2" = {
        mode = "1920x1200";
      };
    };
  };


}
