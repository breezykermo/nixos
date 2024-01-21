{
  lib,
  config,
  pkgs,
  ...
}: {

  imports = [
    # ./hyprland.nix
    # ./waybar.nix
    # ./mako.nix
    # ./rofi.nix
    # ./alacritty.nix
    # ./zathura.nix
    # ./wezterm.nix
  ];

  # options.gui = with lib; {
  #   enable = mkEnableOption "gui module";
  #
  #   laptop = mkEnableOption "laptop mode";
  #
  #   monitor = {
  #     name = mkOption {
  #       type = types.str;
  #       description = "The name of the monitor";
  #     };
  #
  #     width = mkOption {
  #       type = types.int;
  #       default = 1920;
  #       description = "The width of the monitor";
  #     };
  #
  #     height = mkOption {
  #       type = types.int;
  #       default = 1080;
  #       description = "The height of the monitor";
  #     };
  #
  #     scale = mkOption {
  #       type = types.float;
  #       default = 1.0;
  #       description = "The GUI scaling";
  #     };
  #
  #     refreshRate = mkOption {
  #       type = types.int;
  #       default = 60;
  #       description = "The refresh rate of the monitor";
  #     };
  #
  #     variableRefreshRate = mkEnableOption "the monitor has variable refresh rate";
  #
  #     touch = mkEnableOption "the monitor is a touch screen";
  #   };
  # };

  # gui = with lib; {
  #   hyprland = {
  #     enable = mkDefault true;
  #   };
  #   waybar = {
  #     enable = mkDefault true;
  #     modules = {
  #       volume.enable = mkDefault true;
  #       brightness.enable = mkDefault true;
  #       battery.enable = mkDefault true;
  #     };
  #   };
  #   mako.enable = mkDefault true;
  #   rofi.enable = mkDefault true;
  #   wezterm.enable = mkDefault true;
  #   zathura.enable = mkDefault true;
  # };

  config = {
    home.packages = with pkgs;
    [ # Base
      wl-clipboard
      grim
      slurp
      notify-desktop
      wtype
      pavucontrol
      qpwgraph
      wdisplays
      imv
      firefox
      xdg-utils
    ]
    ++ [ # Fonts
      material-design-icons
      devicon
      liberation_ttf
      twitter-color-emoji
    ]
    ++ [ # GTK Theming
    gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
    ];

    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        mpris
          thumbnail
      ];
      config = {
        osc = "no";
        vo = "gpu";
        hwdec = "auto";
      };
    };

    services.playerctld.enable = true;

    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      DSSI_PATH = "$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
      LADSPA_PATH = "$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
      LV2_PATH = "$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
      LXVST_PATH = "$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
      VST_PATH = "$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
      VST3_PATH = "$HOME/.nix-profile/lib/vst3:/run/current-system/sw/lib/vst3";
    };

    fonts.fontconfig.enable = true;
  };
}
