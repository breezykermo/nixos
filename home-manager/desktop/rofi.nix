{
  lib,
  config,
  pkgs,
  ...
}: {
  options.gui.rofi = with lib; {
    enable = mkEnableOption "rofi application launcher";
    theme = mkOption {
      type = types.enum ["dark" "light"];
      default = "dark";
      example = "light";
    };
  };

  config = let
    cfg = config.gui.rofi;
  in
    lib.mkIf cfg.enable {
      programs.rofi = {
        enable = true;
        package = pkgs.rofi-wayland;
        font = "Diosevka 10";
        theme = let
          inherit (config.lib.formats.rasi) mkLiteral;

          background =
            if cfg.theme == "light"
            then "#fbf1c7"
            else "#282828";

          foreground =
            if cfg.theme == "light"
            then "#3c3836"
            else "#ebdbb2";

          selected =
            if cfg.theme == "light"
            then "#ebdbb2"
            else "#3c3836";
        in {
          "*" = {
            background-color = mkLiteral background;
            text-color = mkLiteral foreground;
          };

          window = {
            width = config.gui.monitor.width / 4;
            border-radius = 8;
          };

          mainbox = {
            border = 2;
            padding = 9;
            border-color = mkLiteral "#d79921";
            border-radius = 8;
          };

          "element selected" = {
            background-color = mkLiteral selected;
          };

          "element-text selected" = {
            background-color = mkLiteral selected;
          };

          "element-icon selected" = {
            background-color = mkLiteral selected;
          };

          "element-text" = {
            highlight = mkLiteral "bold #d79921";
            padding = mkLiteral "0 1ch";
          };
        };
      };
    };
}
