{ lib }:

{
  # Rose Pine color palette with variants
  # Reference: https://rosepinetheme.com/

  variants = {
    main = {
      name = "rosepine-main";

      # Backgrounds
      bg0_hard = "#191724";  # Base - darkest
      bg0 = "#1f1d2e";       # Surface
      bg1 = "#26233a";       # Overlay
      bg2 = "#393552";       # Lighter overlay
      bg3 = "#524f67";       # Interpolated
      bg4 = "#6e6a86";       # Muted

      # Foregrounds
      fg0 = "#e0def4";       # Text - brightest
      fg1 = "#e0def4";       # Text
      fg2 = "#908caa";       # Subtle
      fg3 = "#6e6a86";       # Muted
      fg4 = "#524f67";       # Dimmed

      # Colors
      red = "#eb6f92";       # Love
      green = "#31748f";     # Pine (used for success states)
      yellow = "#f6c177";    # Gold
      blue = "#9ccfd8";      # Foam
      purple = "#c4a7e7";    # Iris
      aqua = "#31748f";      # Pine
      orange = "#ebbcba";    # Rose
      gray = "#6e6a86";      # Muted

      # Bright variants
      bright_red = "#eb6f92";
      bright_green = "#31748f";
      bright_yellow = "#f6c177";
      bright_blue = "#9ccfd8";
      bright_purple = "#c4a7e7";
      bright_aqua = "#56949f";
      bright_orange = "#ebbcba";
      bright_gray = "#908caa";
    };

    moon = {
      name = "rosepine-moon";

      # Backgrounds
      bg0_hard = "#232136";  # Base - darkest
      bg0 = "#2a273f";       # Surface
      bg1 = "#393552";       # Overlay
      bg2 = "#44415a";       # Lighter overlay
      bg3 = "#56526e";       # Interpolated
      bg4 = "#6e6a86";       # Muted

      # Foregrounds
      fg0 = "#e0def4";       # Text - brightest
      fg1 = "#e0def4";       # Text
      fg2 = "#908caa";       # Subtle
      fg3 = "#6e6a86";       # Muted
      fg4 = "#56526e";       # Dimmed

      # Colors
      red = "#eb6f92";       # Love
      green = "#3e8fb0";     # Pine (brighter than main)
      yellow = "#f6c177";    # Gold
      blue = "#9ccfd8";      # Foam
      purple = "#c4a7e7";    # Iris
      aqua = "#3e8fb0";      # Pine
      orange = "#ea9a97";    # Rose (slightly different)
      gray = "#6e6a86";      # Muted

      # Bright variants
      bright_red = "#eb6f92";
      bright_green = "#3e8fb0";
      bright_yellow = "#f6c177";
      bright_blue = "#9ccfd8";
      bright_purple = "#c4a7e7";
      bright_aqua = "#56949f";
      bright_orange = "#ea9a97";
      bright_gray = "#908caa";
    };

    dawn = {
      name = "rosepine-dawn";

      # Backgrounds (light theme)
      bg0_hard = "#faf4ed";  # Base - lightest
      bg0 = "#fffaf3";       # Surface
      bg1 = "#f2e9e1";       # Overlay
      bg2 = "#e6ddd5";       # Darker overlay
      bg3 = "#d4cbc3";       # Interpolated
      bg4 = "#9893a5";       # Muted

      # Foregrounds (dark on light)
      fg0 = "#575279";       # Text - darkest
      fg1 = "#575279";       # Text
      fg2 = "#797593";       # Subtle
      fg3 = "#9893a5";       # Muted
      fg4 = "#b5b0c5";       # Lighter

      # Colors
      red = "#b4637a";       # Love
      green = "#286983";     # Pine
      yellow = "#ea9d34";    # Gold
      blue = "#56949f";      # Foam
      purple = "#907aa9";    # Iris
      aqua = "#286983";      # Pine
      orange = "#d7827e";    # Rose
      gray = "#9893a5";      # Muted

      # Bright variants
      bright_red = "#b4637a";
      bright_green = "#286983";
      bright_yellow = "#ea9d34";
      bright_blue = "#56949f";
      bright_purple = "#907aa9";
      bright_aqua = "#56949f";
      bright_orange = "#d7827e";
      bright_gray = "#797593";
    };
  };
}
