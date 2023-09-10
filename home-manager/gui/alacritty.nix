{
  lib,
  config,
  ...
}: {
  options.gui.alacritty = with lib; {
    enable = mkEnableOption "alacritty terminal emulator";
  };

  config = lib.mkIf config.gui.alacritty.enable {
    home.sessionVariables.TERM = "alacritty";
    programs.alacritty = {
      enable = true;
      settings = {
        window.padding = {
          x = 10;
          y = 10;
        };

        font = {
          normal.family = "Diosevka";
          size = 10;
        };

        colors = {
          primary = {
            background = "#282828";
            foreground = "#ebdbb2";
          };

          normal = {
            black = "#282828";
            red = "#cc241d";
            green = "#98971a";
            yellow = "#d79921";
            blue = "#458588";
            magenta = "#b16286";
            cyan = "#689d6a";
            white = "#ebdbb2";
          };

          bright = {
            black = "#504945";
            red = "#fb4934";
            green = "#b8bb26";
            yellow = "#fabd2f";
            blue = "#83a598";
            magenta = "#d3869b";
            cyan = "#8ec07c";
            white = "#fbf1c7";
          };

          dim = {
            black = "#1d2021";
            red = "#9d0006";
            green = "#79740e";
            yellow = "#b57614";
            blue = "#076678";
            magenta = "#8f3f71";
            cyan = "#427b58";
            white = "#d5c4a1";
          };

          indexed_colors = [
            {
              index = 24;
              color = "#076678";
            }
            {
              index = 65;
              color = "#427b58";
            }
            {
              index = 66;
              color = "#458588";
            }
            {
              index = 72;
              color = "#689d6a";
            }
            {
              index = 88;
              color = "#9d0006";
            }
            {
              index = 96;
              color = "#8f3f71";
            }
            {
              index = 100;
              color = "#79740e";
            }
            {
              index = 106;
              color = "#98971a";
            }
            {
              index = 108;
              color = "#8ec07c";
            }
            {
              index = 109;
              color = "#83a598";
            }
            {
              index = 124;
              color = "#cc241d";
            }
            {
              index = 130;
              color = "#af3a03";
            }
            {
              index = 132;
              color = "#b16286";
            }
            {
              index = 136;
              color = "#b57614";
            }
            {
              index = 142;
              color = "#b8bb26";
            }
            {
              index = 166;
              color = "#d65d0e";
            }
            {
              index = 167;
              color = "#fb4934";
            }
            {
              index = 172;
              color = "#d79921";
            }
            {
              index = 175;
              color = "#d3869b";
            }
            {
              index = 208;
              color = "#fe8019";
            }
            {
              index = 214;
              color = "#fabd2f";
            }
            {
              index = 223;
              color = "#ebdbb2";
            }
            {
              index = 229;
              color = "#fbf1c7";
            }
            {
              index = 234;
              color = "#1d2021";
            }
            {
              index = 235;
              color = "#282828";
            }
            {
              index = 236;
              color = "#32302f";
            }
            {
              index = 237;
              color = "#3c3836";
            }
            {
              index = 239;
              color = "#504945";
            }
            {
              index = 241;
              color = "#665c54";
            }
            {
              index = 243;
              color = "#7c6f64";
            }
            {
              index = 245;
              color = "#928374";
            }
            {
              index = 246;
              color = "#a89984";
            }
            {
              index = 248;
              color = "#bdae93";
            }
            {
              index = 250;
              color = "#d5c4a1";
            }
          ];
        };
      };
    };
  };
}
