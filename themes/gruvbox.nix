{ lib }:

{
  # Gruvbox color palette with variants
  # Reference: https://github.com/morhetz/gruvbox

  variants = {
    dark-hard = {
      name = "gruvbox-dark-hard";

      # Backgrounds
      bg0_hard = "#1d2021";
      bg0 = "#282828";
      bg1 = "#3c3836";
      bg2 = "#504945";
      bg3 = "#665c54";
      bg4 = "#7c6f64";

      # Foregrounds
      fg0 = "#fbf1c7";
      fg1 = "#ebdbb2";
      fg2 = "#d5c4a1";
      fg3 = "#bdae93";
      fg4 = "#a89984";

      # Colors
      red = "#fb4934";
      green = "#b8bb26";
      yellow = "#fabd2f";
      blue = "#83a598";
      purple = "#d3869b";
      aqua = "#8ec07c";
      orange = "#fe8019";
      gray = "#928374";

      # Bright variants
      bright_red = "#cc241d";
      bright_green = "#98971a";
      bright_yellow = "#d79921";
      bright_blue = "#458588";
      bright_purple = "#b16286";
      bright_aqua = "#689d6a";
      bright_orange = "#d65d0e";
      bright_gray = "#a89984";
    };

    dark-medium = {
      name = "gruvbox-dark-medium";

      # Backgrounds
      bg0_hard = "#1d2021";
      bg0 = "#282828";
      bg1 = "#3c3836";
      bg2 = "#504945";
      bg3 = "#665c54";
      bg4 = "#7c6f64";

      # Foregrounds
      fg0 = "#fbf1c7";
      fg1 = "#ebdbb2";
      fg2 = "#d5c4a1";
      fg3 = "#bdae93";
      fg4 = "#a89984";

      # Colors (same as hard)
      red = "#fb4934";
      green = "#b8bb26";
      yellow = "#fabd2f";
      blue = "#83a598";
      purple = "#d3869b";
      aqua = "#8ec07c";
      orange = "#fe8019";
      gray = "#928374";

      # Bright variants
      bright_red = "#cc241d";
      bright_green = "#98971a";
      bright_yellow = "#d79921";
      bright_blue = "#458588";
      bright_purple = "#b16286";
      bright_aqua = "#689d6a";
      bright_orange = "#d65d0e";
      bright_gray = "#a89984";
    };

    dark-soft = {
      name = "gruvbox-dark-soft";

      # Backgrounds
      bg0_hard = "#1d2021";
      bg0 = "#32302f";
      bg1 = "#3c3836";
      bg2 = "#504945";
      bg3 = "#665c54";
      bg4 = "#7c6f64";

      # Foregrounds
      fg0 = "#fbf1c7";
      fg1 = "#ebdbb2";
      fg2 = "#d5c4a1";
      fg3 = "#bdae93";
      fg4 = "#a89984";

      # Colors (same as hard)
      red = "#fb4934";
      green = "#b8bb26";
      yellow = "#fabd2f";
      blue = "#83a598";
      purple = "#d3869b";
      aqua = "#8ec07c";
      orange = "#fe8019";
      gray = "#928374";

      # Bright variants
      bright_red = "#cc241d";
      bright_green = "#98971a";
      bright_yellow = "#d79921";
      bright_blue = "#458588";
      bright_purple = "#b16286";
      bright_aqua = "#689d6a";
      bright_orange = "#d65d0e";
      bright_gray = "#a89984";
    };

    dark-pale = {
      name = "gruvbox-dark-pale";

      # Backgrounds (slightly different from official gruvbox)
      bg0_hard = "#1d2021";
      bg0 = "#262626";
      bg1 = "#3a3a3a";
      bg2 = "#4e4e4e";
      bg3 = "#626262";
      bg4 = "#767676";

      # Foregrounds
      fg0 = "#dab997";
      fg1 = "#d5c4a1";
      fg2 = "#bdae93";
      fg3 = "#a89984";
      fg4 = "#928374";

      # Colors (slightly muted)
      red = "#d75f5f";
      green = "#afaf00";
      yellow = "#ffaf00";
      blue = "#83adad";
      purple = "#d485ad";
      aqua = "#85ad85";
      orange = "#ff8700";
      gray = "#928374";

      # Bright variants
      bright_red = "#ff8700";
      bright_green = "#afaf00";
      bright_yellow = "#ffaf00";
      bright_blue = "#83adad";
      bright_purple = "#d485ad";
      bright_aqua = "#85ad85";
      bright_orange = "#ff8700";
      bright_gray = "#a89984";
    };
  };
}
