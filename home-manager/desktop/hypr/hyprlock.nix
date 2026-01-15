{ pkgs, theme, ... }:

let
  # Convert theme colors to hyprlock rgba format (without 0x prefix)
  bgColor = "rgb(${builtins.substring 1 6 theme.colors.bg0_hard})";
  fgColor = "rgb(${builtins.substring 1 6 theme.colors.fg0})";
  accentColor = "rgb(${builtins.substring 1 6 theme.colors.yellow})";
  dimColor = "rgb(${builtins.substring 1 6 theme.colors.bg3})";
in
{
  programs.hyprlock = {
    enable = true;
    package = pkgs.hyprlock;

    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
        no_fade_in = true;
        no_fade_out = true;
        disable_loading_bar = true;
      };

      background = [{
        monitor = "";
        color = bgColor;
        blur_passes = 0;
      }];

      input-field = [{
        monitor = "";
        size = "300, 50";
        outline_thickness = 2;
        dots_size = 0.25;
        dots_spacing = 0.15;
        dots_center = true;
        outer_color = dimColor;
        inner_color = bgColor;
        font_color = fgColor;
        fade_on_empty = false;
        placeholder_text = "";
        hide_input = false;
        check_color = accentColor;
        fail_color = "rgb(${builtins.substring 1 6 theme.colors.red})";
        fail_text = "";
        position = "0, 0";
        halign = "center";
        valign = "center";
      }];

      label = [{
        monitor = "";
        text = "$TIME";
        color = fgColor;
        font_size = 64;
        font_family = "monospace";
        position = "0, 150";
        halign = "center";
        valign = "center";
      }];
    };
  };
}
