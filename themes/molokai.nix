{ lib }:

{
  # Molokai color palette with variants
  # Reference: https://github.com/tomasr/molokai

  variants = {
    # Classic Molokai
    classic = {
      name = "molokai";

      # Backgrounds (very dark, almost black)
      bg0_hard = "#080808";  # Nearly black
      bg0 = "#1b1d1e";       # Standard Molokai background
      bg1 = "#232526";       # Slightly lighter
      bg2 = "#293739";       # Dark gray-green
      bg3 = "#465457";       # Medium gray
      bg4 = "#5f7175";       # Lighter gray

      # Foregrounds (off-white/gray)
      fg0 = "#f8f8f2";       # Bright foreground
      fg1 = "#e6e6e0";       # Dimmed
      fg2 = "#d0d0c8";       # More dimmed
      fg3 = "#75715e";       # Comment color
      fg4 = "#5f5a4b";       # Darker comment

      # Colors (vibrant Molokai palette)
      red = "#f92672";       # Hot pink/magenta
      green = "#a6e22e";     # Bright green
      yellow = "#e6db74";    # Yellow
      blue = "#66d9ef";      # Bright cyan-blue
      purple = "#ae81ff";    # Purple/lavender
      aqua = "#66d9ef";      # Cyan (same as blue in Molokai)
      orange = "#fd971f";    # Orange
      gray = "#465457";      # Gray

      # Bright variants (more saturated)
      bright_red = "#ff3883";
      bright_green = "#b9f442";
      bright_yellow = "#f3ec88";
      bright_blue = "#7ce6f9";
      bright_purple = "#c094ff";
      bright_aqua = "#7ce6f9";
      bright_orange = "#ffa842";
      bright_gray = "#5f7175";
    };

    # Phoenix - warmer Molokai variant
    phoenix = {
      name = "molokai-phoenix";

      # Slightly warmer backgrounds
      bg0_hard = "#0f0a08";  # Warm black
      bg0 = "#1f1a17";       # Warm dark brown
      bg1 = "#2a241f";       # Dark brown
      bg2 = "#3a342b";       # Brown-gray
      bg3 = "#4f4940";       # Medium brown-gray
      bg4 = "#6a6250";       # Light brown-gray

      # Foregrounds
      fg0 = "#f8f8f2";       # Bright foreground
      fg1 = "#e6e6e0";       # Dimmed
      fg2 = "#d0d0c8";       # More dimmed
      fg3 = "#75715e";       # Comment
      fg4 = "#5f5a4b";       # Dark comment

      # Warmer color palette
      red = "#f92672";       # Hot pink/magenta
      green = "#a6e22e";     # Bright green
      yellow = "#f4cf1a";    # More saturated yellow
      blue = "#66d9ef";      # Cyan-blue
      purple = "#ae81ff";    # Purple
      aqua = "#5fd7d7";      # Warmer cyan
      orange = "#fd971f";    # Orange
      gray = "#4f4940";      # Warm gray

      # Bright variants
      bright_red = "#ff3883";
      bright_green = "#b9f442";
      bright_yellow = "#ffe72e";
      bright_blue = "#7ce6f9";
      bright_purple = "#c094ff";
      bright_aqua = "#74e6e6";
      bright_orange = "#ffa842";
      bright_gray = "#6a6250";
    };

    # Vivid - more saturated Molokai
    vivid = {
      name = "molokai-vivid";

      # Backgrounds (standard)
      bg0_hard = "#080808";
      bg0 = "#1b1d1e";
      bg1 = "#232526";
      bg2 = "#293739";
      bg3 = "#465457";
      bg4 = "#5f7175";

      # Foregrounds
      fg0 = "#ffffff";       # Pure white (brighter)
      fg1 = "#f0f0ea";       # Bright
      fg2 = "#d8d8d0";       # Light
      fg3 = "#75715e";       # Comment
      fg4 = "#5f5a4b";       # Dark comment

      # More vivid/saturated colors
      red = "#ff1f5a";       # Very vivid pink
      green = "#9dff00";     # Very vivid green
      yellow = "#fffc00";    # Very vivid yellow
      blue = "#00e8ff";      # Very vivid cyan
      purple = "#b967ff";    # Very vivid purple
      aqua = "#00e8ff";      # Very vivid cyan
      orange = "#ff9500";    # Very vivid orange
      gray = "#465457";      # Gray

      # Bright variants (extremely saturated)
      bright_red = "#ff3370";
      bright_green = "#b4ff3c";
      bright_yellow = "#ffff3c";
      bright_blue = "#3cffff";
      bright_purple = "#d084ff";
      bright_aqua = "#3cffff";
      bright_orange = "#ffaa3c";
      bright_gray = "#6f8185";
    };

    # Dark - darker backgrounds, less saturated
    dark = {
      name = "molokai-dark";

      # Darker backgrounds
      bg0_hard = "#000000";  # Pure black
      bg0 = "#0f1112";       # Very dark
      bg1 = "#18191a";       # Dark
      bg2 = "#1f2223";       # Slightly lighter
      bg3 = "#333637";       # Medium dark
      bg4 = "#4a4d4e";       # Medium gray

      # Foregrounds (less bright)
      fg0 = "#e8e8e0";       # Dimmed white
      fg1 = "#d5d5cd";       # More dimmed
      fg2 = "#b8b8b0";       # Dimmed
      fg3 = "#75715e";       # Comment
      fg4 = "#5f5a4b";       # Dark comment

      # Less saturated colors
      red = "#e01b5d";       # Less vivid pink
      green = "#8fd918";     # Less vivid green
      yellow = "#d4ca63";    # Less vivid yellow
      blue = "#54c7dd";      # Less vivid cyan
      purple = "#9d71e8";    # Less vivid purple
      aqua = "#54c7dd";      # Less vivid cyan
      orange = "#e88c14";    # Less vivid orange
      gray = "#4a4d4e";      # Gray

      # Bright variants (moderately bright)
      bright_red = "#f92c6f";
      bright_green = "#a5d938";
      bright_yellow = "#e6db74";
      bright_blue = "#66d9ef";
      bright_purple = "#ae81ff";
      bright_aqua = "#66d9ef";
      bright_orange = "#fd971f";
      bright_gray = "#5f6465";
    };
  };
}
