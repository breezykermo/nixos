{ config, lib, pkgs, ... }:

{
  imports = [
    ./alacritty.nix
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
    rofi
  ]
  ++ [ # Fonts
    liberation_ttf
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./hypr.conf;
  };

}
