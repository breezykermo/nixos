{
  lib,
  localProfile ? null,
}: let
  themeLib = import ./lib.nix {inherit lib;};
  gruvbox = import ./gruvbox.nix {inherit lib;};
  catppuccin = import ./catppuccin.nix {inherit lib;};
  nord = import ./nord.nix {inherit lib;};
  onedark = import ./onedark.nix {inherit lib;};
  molokai = import ./molokai.nix {inherit lib;};
  rosepine = import ./rosepine.nix {inherit lib;};
  moonfly = import ./moonfly.nix {inherit lib;};

  # ============================================================================
  # THEME CONFIGURATION - Change these values to switch themes
  # ============================================================================

  # Active palette for every machine. `localProfile` (the machine name / flake
  # attr from flake.nix) is still passed in and can be branched on here when a
  # box needs its own palette -- this file is a plain function imported at the
  # flake level, not a NixOS/home-manager module, so it has no access to
  # `config` and cannot read a `custom.*` option; selecting by machine name here
  # is the simplest correct place for it.
  #
  # Options: "gruvbox", "catppuccin", "nord", "onedark", "molokai", "rosepine",
  #          "moonfly"
  activeTheme = "moonfly";
  activeVariant = "default";
  # Gruvbox: "dark-hard", "dark-medium", "dark-soft", "dark-pale"
  # Catppuccin: "mocha", "macchiato", "frappe", "latte"
  # Nord: "polar-night", "snow-storm", "frost", "aurora"
  # OneDark: "dark", "darker", "vivid", "light"
  # Molokai: "classic", "phoenix", "vivid", "dark"
  # Rose Pine: "main", "moon", "dawn"
  # Moonfly: "default" (single palette)

  enableTransparency = true; # Global transparency setting
  opacity = "0.98"; # Default opacity for transparent backgrounds

  # ============================================================================

  # Select the appropriate theme palette
  themePalettes = {
    gruvbox = gruvbox.variants;
    catppuccin = catppuccin.variants;
    nord = nord.variants;
    onedark = onedark.variants;
    molokai = molokai.variants;
    rosepine = rosepine.variants;
    moonfly = moonfly.variants;
  };

  selectedPalette = themePalettes.${activeTheme}.${activeVariant};

  # Vivid theme name mapping (vivid ships its own theme names, which do NOT
  # always match our fullName convention - e.g. we call it "rosepine-main" but
  # vivid calls it "rose-pine"). Used to generate LS_COLORS. An unknown name
  # makes `vivid generate` fail at shell startup, so keep this in sync with
  # `vivid themes`.
  vividThemeName =
    if activeTheme == "gruvbox"
    then
      if activeVariant == "dark-hard"
      then "gruvbox-dark-hard"
      else if activeVariant == "dark-soft"
      then "gruvbox-dark-soft"
      else "gruvbox-dark" # medium/pale -> generic gruvbox-dark
    else if activeTheme == "catppuccin"
    then "catppuccin-${activeVariant}" # mocha/macchiato/frappe/latte match vivid
    else if activeTheme == "nord"
    then "nord" # vivid only ships a single nord theme
    else if activeTheme == "onedark"
    then
      if activeVariant == "light"
      then "one-light"
      else "one-dark"
    else if activeTheme == "molokai"
    then "molokai" # vivid only ships a single molokai theme
    else if activeTheme == "rosepine"
    then
      if activeVariant == "moon"
      then "rose-pine-moon"
      else if activeVariant == "dawn"
      then "rose-pine-dawn"
      else "rose-pine" # main
    else if activeTheme == "moonfly"
    # vivid ships no moonfly theme. "ansi" emits only the 16 ANSI codes, so
    # LS_COLORS is rendered with whatever palette the terminal carries -- which
    # is this palette (see the ghostty `palette =` block in
    # home-manager/desktop/default.nix). Exact by construction, at the cost of
    # the extra truecolor shades a native vivid theme would use.
    then "ansi"
    else "gruvbox-dark"; # Safe fallback
in {
  inherit themeLib;

  # Theme metadata
  name = activeTheme;
  variant = activeVariant;
  fullName = selectedPalette.name;
  vividTheme = vividThemeName;

  # Transparency settings
  transparency = {
    enabled = enableTransparency;
    opacity = opacity;
    opacityFloat = builtins.fromJSON opacity;
  };

  # Color palette - directly expose all colors
  colors = selectedPalette;

  # Convenient aliases for common use cases
  background = selectedPalette.bg0_hard;
  backgroundAlt = selectedPalette.bg1;
  foreground = selectedPalette.fg0;
  foregroundAlt = selectedPalette.fg1;

  # Border colors with sensible defaults
  activeBorder = selectedPalette.aqua;
  inactiveBorder = selectedPalette.bg3;

  # Status colors
  success = selectedPalette.green;
  warning = selectedPalette.yellow;
  error = selectedPalette.red;
  info = selectedPalette.blue;

  # Helper functions bound to current theme
  helpers = {
    # Convert current theme color to rgba
    toRgba = color: alpha: themeLib.hexToRgba color alpha;

    # Convert to Hyprland rgba format
    toHyprRgba = color: alphaHex: themeLib.hexToRgbaHex color alphaHex;

    # Get color with theme opacity applied
    withOpacity = color: themeLib.withOpacity color opacity;

    # Convert hex color to 256-color terminal code
    to256Color = color: themeLib.hexTo256Color color;
  };
}
