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
    settings = {
      font = {
        normal.family = "Liberation Mono";
        size = 14;
      };
      shell = {
        program = "${pkgs.fish}/bin/fish";
        args = [ "--interactive" ];
      };
      draw_bold_text_with_bright_colors = true;
    };
  };

}
