{ lib }:

{
  # Catppuccin color palette
  # Reference: https://github.com/catppuccin/catppuccin

  variants = {
    mocha = {
      name = "catppuccin-mocha";

      # Backgrounds
      bg0_hard = "#11111b";
      bg0 = "#1e1e2e";
      bg1 = "#181825";
      bg2 = "#313244";
      bg3 = "#45475a";
      bg4 = "#585b70";

      # Foregrounds
      fg0 = "#cdd6f4";
      fg1 = "#bac2de";
      fg2 = "#a6adc8";
      fg3 = "#9399b2";
      fg4 = "#7f849c";

      # Colors
      red = "#f38ba8";
      green = "#a6e3a1";
      yellow = "#f9e2af";
      blue = "#89b4fa";
      purple = "#cba6f7";
      aqua = "#94e2d5";
      orange = "#fab387";
      gray = "#6c7086";

      # Bright variants (same as regular for catppuccin)
      bright_red = "#f38ba8";
      bright_green = "#a6e3a1";
      bright_yellow = "#f9e2af";
      bright_blue = "#89b4fa";
      bright_purple = "#cba6f7";
      bright_aqua = "#94e2d5";
      bright_orange = "#fab387";
      bright_gray = "#7f849c";
    };

    macchiato = {
      name = "catppuccin-macchiato";

      # Backgrounds
      bg0_hard = "#181926";
      bg0 = "#24273a";
      bg1 = "#1e2030";
      bg2 = "#363a4f";
      bg3 = "#494d64";
      bg4 = "#5b6078";

      # Foregrounds
      fg0 = "#cad3f5";
      fg1 = "#b8c0e0";
      fg2 = "#a5adcb";
      fg3 = "#939ab7";
      fg4 = "#8087a2";

      # Colors
      red = "#ed8796";
      green = "#a6da95";
      yellow = "#eed49f";
      blue = "#8aadf4";
      purple = "#c6a0f6";
      aqua = "#8bd5ca";
      orange = "#f5a97f";
      gray = "#6e738d";

      # Bright variants
      bright_red = "#ed8796";
      bright_green = "#a6da95";
      bright_yellow = "#eed49f";
      bright_blue = "#8aadf4";
      bright_purple = "#c6a0f6";
      bright_aqua = "#8bd5ca";
      bright_orange = "#f5a97f";
      bright_gray = "#8087a2";
    };

    frappe = {
      name = "catppuccin-frappe";

      # Backgrounds
      bg0_hard = "#232634";
      bg0 = "#303446";
      bg1 = "#292c3c";
      bg2 = "#414559";
      bg3 = "#51576d";
      bg4 = "#626880";

      # Foregrounds
      fg0 = "#c6d0f5";
      fg1 = "#b5bfe2";
      fg2 = "#a5adce";
      fg3 = "#949cbb";
      fg4 = "#838ba7";

      # Colors
      red = "#e78284";
      green = "#a6d189";
      yellow = "#e5c890";
      blue = "#8caaee";
      purple = "#ca9ee6";
      aqua = "#81c8be";
      orange = "#ef9f76";
      gray = "#737994";

      # Bright variants
      bright_red = "#e78284";
      bright_green = "#a6d189";
      bright_yellow = "#e5c890";
      bright_blue = "#8caaee";
      bright_purple = "#ca9ee6";
      bright_aqua = "#81c8be";
      bright_orange = "#ef9f76";
      bright_gray = "#838ba7";
    };

    latte = {
      name = "catppuccin-latte";

      # Backgrounds (light theme)
      bg0_hard = "#dce0e8";
      bg0 = "#eff1f5";
      bg1 = "#e6e9ef";
      bg2 = "#ccd0da";
      bg3 = "#bcc0cc";
      bg4 = "#acb0be";

      # Foregrounds
      fg0 = "#4c4f69";
      fg1 = "#5c5f77";
      fg2 = "#6c6f85";
      fg3 = "#7c7f93";
      fg4 = "#8c8fa1";

      # Colors
      red = "#d20f39";
      green = "#40a02b";
      yellow = "#df8e1d";
      blue = "#1e66f5";
      purple = "#8839ef";
      aqua = "#179299";
      orange = "#fe640b";
      gray = "#9ca0b0";

      # Bright variants
      bright_red = "#d20f39";
      bright_green = "#40a02b";
      bright_yellow = "#df8e1d";
      bright_blue = "#1e66f5";
      bright_purple = "#8839ef";
      bright_aqua = "#179299";
      bright_orange = "#fe640b";
      bright_gray = "#8c8fa1";
    };
  };
}
