{
  lib,
  config,
  ...
}: {
  options.gui.raw-browser = with lib; {
    enable = mkEnableOption "raw-browser";
  };

  config = {
    programs.raw-browser = lib.mkIf config.gui.raw-browser.enable {
      enable = true;

      config = {
        font = {
          size = {
            default = 14;
            monospace = 14;
          };
          default = "Diosevka";
          monospace = "Diosevka";
        };

        devtools = true;
        local-storage = true;
        offline-cache = true;
        page-cache = true;
        resizable-text-areas = true;
        site-specific-quirks = false;
        smooth-scrolling = false;
        spatial-navigation = true;

        history-file = "$HOME/files/raw-browser-history";
        search-query = "http://10.100.0.1:8090/yacysearch.html?query=";
        menu-command = "rofi -dmenu -p 'search the web: ' -i -matching fuzzy";
      };

      style = ''
        *::selection {
          background: #458588FF;
        }

        ::-webkit-scrollbar {
          height: 0;
          width: 0;
        }
      '';
    };
  };
}
