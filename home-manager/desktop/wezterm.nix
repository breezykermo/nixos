{
  lib,
  config,
  ...
}: {
  options.gui.wezterm = with lib; {
    enable = mkEnableOption "wezterm terminal emulator";
    theme = mkOption {
      type = types.enum ["dark" "light"];
      default = "dark";
      example = "light";
    };
  };

  config = let
    cfg = config.gui.wezterm;
    theme =
      if cfg.theme == "light"
      then "Gruvbox Light"
      else "GruvboxDark";
  in
    lib.mkIf cfg.enable {
      home.sessionVariables.TERM = "wezterm";
      programs.wezterm = {
        enable = true;

        extraConfig = ''
          local act = wezterm.action

          return {
            font = wezterm.font("Diosevka"),
            font_size = 10.0,
            color_scheme = "${theme}",
            hide_tab_bar_if_only_one_tab = true,
            bold_brightens_ansi_colors = "No",
            check_for_updates = false,
            hide_mouse_cursor_when_typing = false,
            mouse_bindings = {
              {
                event = { Down = { streak = 1, button = { WheelUp = 1 } } },
                mods = 'NONE',
                action = act.ScrollByLine(-3),
              },
              {
                event = { Down = { streak = 1, button = { WheelDown = 1 } } },
                mods = 'NONE',
                action = act.ScrollByLine(3),
              },
              {
                event = { Down = { streak = 1, button = { WheelUp = 1 } } },
                mods = 'CTRL',
                action = act.IncreaseFontSize,
              },
              {
                event = { Down = { streak = 1, button = { WheelDown = 1 } } },
                mods = 'CTRL',
                action = act.DecreaseFontSize
              },
            },
          }
        '';
      };
    };
}
