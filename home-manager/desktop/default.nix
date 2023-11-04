{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./mako.nix
    ./rofi.nix
    ./alacritty.nix
    ./zathura.nix
    ./raw-browser.nix
    ./wezterm.nix
  ];

  options.gui = with lib; {
    enable = mkEnableOption "gui module";

    laptop = mkEnableOption "laptop mode";

    monitor = {
      name = mkOption {
        type = types.str;
        description = "The name of the monitor";
      };

      width = mkOption {
        type = types.int;
        default = 1920;
        description = "The width of the monitor";
      };

      height = mkOption {
        type = types.int;
        default = 1080;
        description = "The height of the monitor";
      };

      scale = mkOption {
        type = types.float;
        default = 1.0;
        description = "The GUI scaling";
      };

      refreshRate = mkOption {
        type = types.int;
        default = 60;
        description = "The refresh rate of the monitor";
      };

      variableRefreshRate = mkEnableOption "the monitor has variable refresh rate";

      touch = mkEnableOption "the monitor is a touch screen";
    };
  };

  config = lib.mkIf config.gui.enable {
    home.packages = with pkgs;
      [
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
        thunderbird
        wineWowPackages.waylandFull
        xdg-utils
      ]
      ++ [
        # Fonts
        material-design-icons
        devicon
        liberation_ttf
        twitter-color-emoji
      ]
      ++ [
        # GTK Theming
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

    # Update fonts
    fonts.fontconfig.enable = true;

    gui = with lib; {
      hyprland = {
        enable = mkDefault true;
      };
      waybar = {
        enable = mkDefault true;
        modules = mkIf config.gui.laptop {
          volume.enable = mkDefault true;
          brightness.enable = mkDefault true;
          battery.enable = mkDefault true;
        };
      };
      raw-browser.enable = mkDefault false;
      mako.enable = mkDefault true;
      rofi.enable = mkDefault true;
      wezterm.enable = mkDefault true;
      zathura.enable = mkDefault true;
    };

    gtk = let
      dpi = 96;
    in {
      enable = true;
      font = {
        name = "Diosevka";
        package = pkgs.diosevka;
        size = 10;
      };

      iconTheme = {
        name = "oomox-gruvbox-dark";
        package = pkgs.gruvbox-dark-icons-gtk;
      };

      theme = {
        name = lib.mkDefault "gruvbox-dark";
        package = lib.mkDefault pkgs.gruvbox-dark-gtk;
      };

      # Unfortunately this only works in firefox...
      # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
      # https://gitlab.freedesktop.org/wlroots/wlroots/-/merge_requests/1324
      cursorTheme = {
        name = "Vanilla-DMZ-AA";
        package = pkgs.vanilla-dmz;
      };

      gtk2 = {
        configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        extraConfig = ''
          gtk-xft-dpi = ${toString (dpi * 1024)}
        '';
      };

      # The reason for the factor of 1024 is because it's later divided
      # by that same factor in webkitgtk.
      gtk3.extraConfig.gtk-xft-dpi = dpi * 1024;

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-theme-name = "gruvbox-dark";
        gtk-icon-theme-name = "oomox-gruvbox-dark";
        gtk-cursor-theme-name = "Vanilla-DMZ-AA";
        gtk-xft-dpi = dpi * 1024;
      };
    };

    # Make qt mimic the GTK theme
    qt = {
      enable = true;
      platformTheme = "gtk";
      style.name = "gtk2";
    };
  };
}
