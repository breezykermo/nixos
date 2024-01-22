{ config, lib, pkgs, ... }:

{
  imports = [
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

  programs.alacritty = {
    enable = true;
    settings = builtins.readFile ./alacritty.nix;
  };

}
