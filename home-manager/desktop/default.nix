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

  programs.sway.enable = true;
  sound.enable = true;
  nixpkgs.config.pulseaudio = true;
  hardware.pulseaudio.enable = true;

  config = {
    home.packages = with pkgs;
    [ # Base
      firefox
      xdg-utils
    ]
    ++ [ # Fonts
      liberation_ttf
    ];
  };
}
