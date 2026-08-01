{lib}: {
  # Moonfly color palette (bluz71)
  # Reference: https://github.com/bluz71/vim-moonfly-colors
  #            https://terminalcolors.com/themes/moonfly/default/
  #
  # Moonfly ships a single palette (no light/soft/hard variants), so there is
  # exactly one variant here, named "default".
  #
  # The colors/bright_* slots are the theme's ANSI 0-15 (see the ghostty
  # `palette =` block in home-manager/desktop/default.nix, which maps
  # 0 -> bg2, 7 -> fg2, 8 -> gray, 15 -> fg0), so they are copied verbatim from
  # the upstream terminal palette rather than picked for their names -- e.g.
  # ANSI bright-cyan really is moonfly's "lime" green.

  variants = {
    default = {
      name = "moonfly-default";

      # Backgrounds: moonfly's charcoal-grey ramp. bg2 doubles as ANSI black
      # (grey0, also the visual-selection background upstream).
      bg0_hard = "#080808"; # black - the moonfly background
      bg0 = "#121212"; # grey7
      bg1 = "#1c1c1c"; # grey11
      bg2 = "#323437"; # grey0 / ANSI 0
      bg3 = "#4e4e4e"; # grey30 - inactive borders
      bg4 = "#626262"; # grey39

      # Foregrounds, brightest first (repo convention: fg0 is the main text
      # color). fg0 is moonfly's `white`, what upstream paints Normal text with.
      # The ANSI white slots land one grey step below their upstream values
      # (7 wants #c6c6c6, 15 wants #e4e4e4) because fg0 has to serve both ANSI
      # 15 and `foreground`, and moonfly's soft grey text is the more visible
      # half of that trade.
      fg0 = "#c6c6c6"; # white - main text / ANSI 15
      fg1 = "#bdbdbd"; # the upstream terminal foreground
      fg2 = "#b2b2b2"; # grey70 / ANSI 7
      fg3 = "#949494"; # grey58
      fg4 = "#808080"; # grey50

      # Colors (ANSI 1-6, plus orange/gray which have no ANSI slot)
      red = "#ff5454";
      green = "#8cc85f";
      yellow = "#e3c78a";
      blue = "#80a0ff";
      purple = "#cf87e8"; # violet
      aqua = "#79dac8"; # turquoise - the moonfly accent
      orange = "#de935f";
      gray = "#949494"; # grey58 / ANSI 8

      # Bright variants (ANSI 9-14, plus orange/gray)
      bright_red = "#ff5189"; # crimson
      bright_green = "#36c692"; # emerald
      bright_yellow = "#c6c684"; # khaki
      bright_blue = "#74b2ff"; # sky
      bright_purple = "#ae81ff"; # purple
      bright_aqua = "#85dc85"; # lime (moonfly's ANSI bright-cyan)
      bright_orange = "#f09479"; # coral
      bright_gray = "#e4e4e4"; # grey89 / bright white
    };
  };
}
