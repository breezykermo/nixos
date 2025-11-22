{ lib }:

{
  # Nord color palette with variants
  # Reference: https://www.nordtheme.com/docs/colors-and-palettes

  variants = {
    # Main dark variant using Polar Night as background
    polar-night = {
      name = "nord";

      # Polar Night (dark backgrounds) - nord0 through nord3
      bg0_hard = "#2e3440";  # nord0 - darkest
      bg0 = "#3b4252";       # nord1 - dark
      bg1 = "#434c5e";       # nord2 - darker gray
      bg2 = "#4c566a";       # nord3 - dark gray
      bg3 = "#5e6b82";       # Interpolated lighter
      bg4 = "#6f7c94";       # Interpolated lighter still

      # Snow Storm (light foregrounds) - nord4 through nord6
      fg0 = "#eceff4";       # nord6 - lightest/brightest
      fg1 = "#e5e9f0";       # nord5 - bright
      fg2 = "#d8dee9";       # nord4 - light
      fg3 = "#c0c5ce";       # Dimmed
      fg4 = "#a8adb8";       # Dimmed further

      # Frost (blue accent colors) - nord7 through nord10
      red = "#bf616a";       # nord11 - Aurora red
      green = "#a3be8c";     # nord14 - Aurora green
      yellow = "#ebcb8b";    # nord13 - Aurora yellow
      blue = "#81a1c1";      # nord9 - Frost blue
      purple = "#b48ead";    # nord15 - Aurora purple
      aqua = "#88c0d0";      # nord8 - Frost cyan
      orange = "#d08770";    # nord12 - Aurora orange
      gray = "#4c566a";      # nord3

      # Bright variants (using brighter Frost and Aurora colors)
      bright_red = "#bf616a";
      bright_green = "#a3be8c";
      bright_yellow = "#ebcb8b";
      bright_blue = "#5e81ac";    # nord10 - darker frost blue
      bright_purple = "#b48ead";
      bright_aqua = "#8fbcbb";    # nord7 - brightest frost
      bright_orange = "#d08770";
      bright_gray = "#d8dee9";    # nord4
    };

    # Light variant using Snow Storm as background
    snow-storm = {
      name = "nord-light";

      # Snow Storm (light backgrounds) - inverted for light theme
      bg0_hard = "#eceff4";  # nord6 - lightest
      bg0 = "#e5e9f0";       # nord5 - bright
      bg1 = "#d8dee9";       # nord4 - light gray
      bg2 = "#c0c5ce";       # Dimmed
      bg3 = "#a8adb8";       # Dimmed more
      bg4 = "#8f95a0";       # Dimmed further

      # Polar Night (dark foregrounds) - inverted for light theme
      fg0 = "#2e3440";       # nord0 - darkest text
      fg1 = "#3b4252";       # nord1 - dark text
      fg2 = "#434c5e";       # nord2 - medium text
      fg3 = "#4c566a";       # nord3 - light text
      fg4 = "#5e6b82";       # Lighter text

      # Keep Aurora and Frost colors the same (they work on light backgrounds)
      red = "#bf616a";       # nord11
      green = "#a3be8c";     # nord14
      yellow = "#ebcb8b";    # nord13
      blue = "#5e81ac";      # nord10
      purple = "#b48ead";    # nord15
      aqua = "#88c0d0";      # nord8
      orange = "#d08770";    # nord12
      gray = "#4c566a";      # nord3

      # Bright variants
      bright_red = "#bf616a";
      bright_green = "#a3be8c";
      bright_yellow = "#ebcb8b";
      bright_blue = "#81a1c1";    # nord9
      bright_purple = "#b48ead";
      bright_aqua = "#8fbcbb";    # nord7
      bright_orange = "#d08770";
      bright_gray = "#2e3440";    # nord0
    };

    # Frost variant - emphasizes blue tones
    frost = {
      name = "nord-frost";

      # Slightly blue-tinted backgrounds
      bg0_hard = "#2b303b";  # Cooler nord0
      bg0 = "#353b49";       # Cooler nord1
      bg1 = "#3f4757";       # Cooler nord2
      bg2 = "#4a5466";       # Cooler nord3
      bg3 = "#5a6478";       # Lighter cool
      bg4 = "#6a7488";       # Lighter cool

      # Snow Storm foregrounds
      fg0 = "#eceff4";       # nord6
      fg1 = "#e5e9f0";       # nord5
      fg2 = "#d8dee9";       # nord4
      fg3 = "#c0c5ce";       # Dimmed
      fg4 = "#a8adb8";       # Dimmed

      # Emphasize Frost colors
      red = "#bf616a";       # nord11
      green = "#a3be8c";     # nord14
      yellow = "#ebcb8b";    # nord13
      blue = "#8fbcbb";      # nord7 - brightest frost (emphasized)
      purple = "#b48ead";    # nord15
      aqua = "#88c0d0";      # nord8 - bright cyan (emphasized)
      orange = "#d08770";    # nord12
      gray = "#4c566a";      # nord3

      # Bright variants emphasizing frost
      bright_red = "#bf616a";
      bright_green = "#a3be8c";
      bright_yellow = "#ebcb8b";
      bright_blue = "#8fbcbb";    # nord7 - brightest
      bright_purple = "#b48ead";
      bright_aqua = "#88c0d0";    # nord8
      bright_orange = "#d08770";
      bright_gray = "#d8dee9";    # nord4
    };

    # Aurora variant - emphasizes warm aurora colors
    aurora = {
      name = "nord-aurora";

      # Polar Night backgrounds
      bg0_hard = "#2e3440";  # nord0
      bg0 = "#3b4252";       # nord1
      bg1 = "#434c5e";       # nord2
      bg2 = "#4c566a";       # nord3
      bg3 = "#5e6b82";       # Lighter
      bg4 = "#6f7c94";       # Lighter

      # Snow Storm foregrounds
      fg0 = "#eceff4";       # nord6
      fg1 = "#e5e9f0";       # nord5
      fg2 = "#d8dee9";       # nord4
      fg3 = "#c0c5ce";       # Dimmed
      fg4 = "#a8adb8";       # Dimmed

      # Emphasize Aurora colors (warmer palette)
      red = "#bf616a";       # nord11 - emphasized
      green = "#a3be8c";     # nord14 - emphasized
      yellow = "#ebcb8b";    # nord13 - emphasized
      blue = "#81a1c1";      # nord9
      purple = "#b48ead";    # nord15 - emphasized
      aqua = "#88c0d0";      # nord8
      orange = "#d08770";    # nord12 - emphasized
      gray = "#4c566a";      # nord3

      # Bright aurora variants
      bright_red = "#d06f79";     # Brighter red
      bright_green = "#b1d196";   # Brighter green
      bright_yellow = "#f0d399";  # Brighter yellow
      bright_blue = "#88aaca";    # Brighter blue
      bright_purple = "#c199ba";  # Brighter purple
      bright_aqua = "#93ccd7";    # Brighter cyan
      bright_orange = "#daa082";  # Brighter orange
      bright_gray = "#d8dee9";    # nord4
    };
  };
}
