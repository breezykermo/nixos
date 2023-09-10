{
  lib,
  config,
  ...
}: {
  options.gui.mako = with lib; {
    enable = mkEnableOption "mako notification daemon";
    theme = mkOption {
      type = types.enum ["dark" "light"];
      default = "dark";
      example = "light";
    };
  };

  config = let
    cfg = config.gui.rofi;

    background =
      if cfg.theme == "light"
      then "#fbf1c7"
      else "#282828";

    foreground =
      if cfg.theme == "light"
      then "#3c3836"
      else "#ebdbb2";
  in
    lib.mkIf cfg.enable {
      services.mako = {
        enable = true;
        anchor = "center";
        backgroundColor = background;
        borderColor = "#d79921";
        textColor = foreground;
        borderSize = 2;
        borderRadius = 8;
        width = 256;
        font = "Diosevka 10";
        sort = "+time";
        defaultTimeout = 3000; # Three seconds
        margin = "16";
      };
    };
}
