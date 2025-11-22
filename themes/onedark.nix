{ lib }:

{
  # One Dark color palette with variants
  # Reference: https://github.com/atom/one-dark-syntax

  variants = {
    # Classic One Dark
    dark = {
      name = "onedark";

      # Backgrounds (dark grays)
      bg0_hard = "#1e2127";  # Darker than standard
      bg0 = "#282c34";       # Standard One Dark background
      bg1 = "#2c313a";       # Slightly lighter
      bg2 = "#3e4451";       # Lighter gray
      bg3 = "#4b5263";       # Comment gray
      bg4 = "#5c6370";       # Lighter comment gray

      # Foregrounds (light grays/white)
      fg0 = "#abb2bf";       # Standard foreground
      fg1 = "#9da5b4";       # Dimmed
      fg2 = "#828997";       # More dimmed
      fg3 = "#5c6370";       # Comment color
      fg4 = "#4b5263";       # Darker comment

      # Colors
      red = "#e06c75";       # Red
      green = "#98c379";     # Green
      yellow = "#e5c07b";    # Yellow/gold
      blue = "#61afef";      # Blue
      purple = "#c678dd";    # Purple/magenta
      aqua = "#56b6c2";      # Cyan
      orange = "#d19a66";    # Orange
      gray = "#5c6370";      # Gray

      # Bright variants (slightly brighter versions)
      bright_red = "#e88388";
      bright_green = "#a8d28e";
      bright_yellow = "#eacf92";
      bright_blue = "#7ec0f7";
      bright_purple = "#d68de8";
      bright_aqua = "#6dc3cf";
      bright_orange = "#dca877";
      bright_gray = "#6d7583";
    };

    # Darker One Dark variant
    darker = {
      name = "onedark-darker";

      # Darker backgrounds
      bg0_hard = "#13161b";  # Much darker
      bg0 = "#1b1f26";       # Darker background
      bg1 = "#21252b";       # Dark
      bg2 = "#2c313a";       # Medium dark
      bg3 = "#3e4451";       # Gray
      bg4 = "#4b5263";       # Lighter gray

      # Foregrounds
      fg0 = "#abb2bf";       # Standard foreground
      fg1 = "#9da5b4";       # Dimmed
      fg2 = "#828997";       # More dimmed
      fg3 = "#5c6370";       # Comment color
      fg4 = "#4b5263";       # Darker comment

      # Colors (same as classic)
      red = "#e06c75";
      green = "#98c379";
      yellow = "#e5c07b";
      blue = "#61afef";
      purple = "#c678dd";
      aqua = "#56b6c2";
      orange = "#d19a66";
      gray = "#5c6370";

      # Bright variants
      bright_red = "#e88388";
      bright_green = "#a8d28e";
      bright_yellow = "#eacf92";
      bright_blue = "#7ec0f7";
      bright_purple = "#d68de8";
      bright_aqua = "#6dc3cf";
      bright_orange = "#dca877";
      bright_gray = "#6d7583";
    };

    # Vivid One Dark - more saturated colors
    vivid = {
      name = "onedark-vivid";

      # Backgrounds (standard)
      bg0_hard = "#1e2127";
      bg0 = "#282c34";
      bg1 = "#2c313a";
      bg2 = "#3e4451";
      bg3 = "#4b5263";
      bg4 = "#5c6370";

      # Foregrounds
      fg0 = "#abb2bf";
      fg1 = "#9da5b4";
      fg2 = "#828997";
      fg3 = "#5c6370";
      fg4 = "#4b5263";

      # More vivid/saturated colors
      red = "#ef596f";       # More vivid red
      green = "#89ca78";     # More vivid green
      yellow = "#e5c07b";    # Yellow
      blue = "#61afef";      # Blue
      purple = "#d55fde";    # More vivid purple
      aqua = "#2bbac5";      # More vivid cyan
      orange = "#d19a66";    # Orange
      gray = "#5c6370";      # Gray

      # Bright vivid variants
      bright_red = "#f77383";
      bright_green = "#9dd98d";
      bright_yellow = "#f0d399";
      bright_blue = "#74bcf8";
      bright_purple = "#e278eb";
      bright_aqua = "#3fc9d4";
      bright_orange = "#e5b079";
      bright_gray = "#6d7583";
    };

    # Light One Dark variant
    light = {
      name = "onedark-light";

      # Light backgrounds
      bg0_hard = "#fafafa";  # Brightest
      bg0 = "#f0f0f0";       # Bright
      bg1 = "#e6e6e6";       # Light gray
      bg2 = "#d0d0d0";       # Medium gray
      bg3 = "#b4b4b4";       # Darker gray
      bg4 = "#9e9e9e";       # Dark gray

      # Dark foregrounds
      fg0 = "#383a42";       # Dark text
      fg1 = "#4b4e55";       # Medium dark
      fg2 = "#696c77";       # Medium
      fg3 = "#9da5b4";       # Light
      fg4 = "#c2c7d1";       # Very light

      # Colors adjusted for light background
      red = "#e45649";       # Darker red
      green = "#50a14f";     # Darker green
      yellow = "#c18401";    # Darker yellow
      blue = "#0184bc";      # Darker blue
      purple = "#a626a4";    # Darker purple
      aqua = "#0997b3";      # Darker cyan
      orange = "#986801";    # Darker orange
      gray = "#a0a1a7";      # Medium gray

      # Bright variants for light theme
      bright_red = "#e45649";
      bright_green = "#50a14f";
      bright_yellow = "#c18401";
      bright_blue = "#0184bc";
      bright_purple = "#a626a4";
      bright_aqua = "#0997b3";
      bright_orange = "#986801";
      bright_gray = "#383a42";
    };
  };
}
