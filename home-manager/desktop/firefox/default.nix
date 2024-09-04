{ pkgs, ... }:
{

  home.packages = with pkgs; [
    brave
  ];

  # user.sessionVariables.BROWSER = "firefox";
  programs.chromium.enable = true;
  programs.firefox = {
    enable = true;
    # package = pkgs.firefox.override {cfg.enableTridactylNative = true;};
    profiles = {
      default = {
        id = 0;
        name = "default";
        # extensions = with (inputs.rycee-nurpkgs.lib.${system}).firefox-addons; [
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

        userChrome = builtins.readFile ./userChrome.css;
      };
    };
  };
}

