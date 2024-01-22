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
  ]
  ++ [ # Fonts
    liberation_ttf
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "ALT";
      bind =
      [
        "$mod, w, exec, firefox"
      ]
      ++ (
        builtins.concatLists (builtins.genList (
          x: let
            ws = let
              c = (x + 1) / 10;
            in
              builtins.toString (x + 1 - (c * 10));
          in [
            "$mod, ${ws}, workspace, ${toString (x + 1)}"
            "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
          ]
        ) 10)
      );
    };
  };

}
