{ config, lib, pkgs, ... }:

{
  imports = [];

  home.packages = with pkgs;
  [ # Base
    xdg-utils
    ripgrep
    fd
  ]
  ++ [ # Fonts
    liberation_ttf
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./hypr.conf;
  };

  programs.firefox = {
    enable = true;
    # package = pkgs.firefox.override {cfg.enableTridactylNative = true;};
    profiles = {
      default = {
        id = 0;
        name = "default";
        # extensions = with rycee-nurpkgs.firefox-addons; [
        #   aria2-integration
        #     buster-captcha-solver
        #     clearurls
        #     decentraleyes
        #     keepassxc-browser
        #     libredirect
        #     no-pdf-download
        #     react-devtools
        #     reduxdevtools
        #     translate-web-pages
        #     tridactyl
        #     ublock-origin
        # ];

        search = {
          force = true;
          default = "DuckDuckGo";
          engines = {
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Wiki" = {
              urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@nw" ];
            };
            "Wikipedia (en)".metaData.alias = "@wiki";
            "Google".metaData.hidden = true;
            "Amazon.com".metaData.hidden = true;
            "Bing".metaData.hidden = true;
            "eBay".metaData.hidden = true;
          };
        };
        settings = {
          "gfx.webrender.all" = true; # Force enable GPU acceleration
          "media.ffmpeg.vaapi.enabled" = true;
          "widget.dmabuf.force-enabled" = true; # Required in recent Firefoxes

          "extensions.pocket.enabled" = false;
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_ever_enabled" = true;
        };
        extraConfig = ''
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("full-screen-api.ignore-widgets", true);
        user_pref("media.ffmpeg.vaapi.enabled", true);
        user_pref("media.rdd-vpx.enabled", true);
        '';

        userChrome = builtins.readFile ./firefox.userChrome.css;
      };
    };
  };

  programs.rofi = {
    enable = true;
    theme = "gruvbox-dark";
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "Liberation Mono";
        size = 12;
      };
      window.decorations = "none";
      scrolling.history = 0;
      shell = {
        program = "${pkgs.fish}/bin/fish";
        args = [ "--interactive" ];
      };
      colors = {
        draw_bold_text_with_bright_colors = true;
        primary = {
          background = "0x1d2021";
          foreground = "0xd5c4a1";
        };
        cursor = {
          text = "0x1d2021";
          cursor = "0xd5c4a1";
        };
        bright = {
          black =   "0x665c54";
          red =     "0xfe8019";
          green =   "0x3c3836";
          yellow =  "0x504945";
          blue =    "0xbdae93";
          magenta = "0xebdbb2";
          cyan =    "0xd65d0e";
          white =   "0xfbf1c7";
        };
        normal = {
          black =   "0x1d2021";
          red =     "0xfb4934";
          green =   "0xb8bb26";
          yellow =  "0xfabd2f";
          blue =    "0x83a598";
          magenta = "0xd3869b";
          cyan =    "0x8ec07c";
          white =   "0xd5c4a3";
        };
      };
      keyboard.bindings = [
        { key = "C";  mods = "Control";   action = "Copy"; } 
        { key = "V";  mods = "Control";   action = "Paste"; } 
        { key = "J";  mods = "Shift|Alt"; action = "DecreaseFontSize"; } 
        { key = "K";  mods = "Shift|Alt"; action = "IncreaseFontSize"; } 
      ];
    };
  };

  services.dropbox = {
    enable =  true;
  };
}
