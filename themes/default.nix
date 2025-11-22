{ lib }:

let
  themeLib = import ./lib.nix { inherit lib; };
  gruvbox = import ./gruvbox.nix { inherit lib; };
  catppuccin = import ./catppuccin.nix { inherit lib; };
  nord = import ./nord.nix { inherit lib; };
  onedark = import ./onedark.nix { inherit lib; };
  molokai = import ./molokai.nix { inherit lib; };

  # ============================================================================
  # THEME CONFIGURATION - Change these values to switch themes
  # ============================================================================

  activeTheme = "gruvbox";           # Options: "gruvbox", "catppuccin", "nord", "onedark", "molokai"
  activeVariant = "dark-hard";       # Gruvbox: "dark-hard", "dark-medium", "dark-soft", "dark-pale"
                                     # Catppuccin: "mocha", "macchiato", "frappe", "latte"
                                     # Nord: "polar-night", "snow-storm", "frost", "aurora"
                                     # OneDark: "dark", "darker", "vivid", "light"
                                     # Molokai: "classic", "phoenix", "vivid", "dark"

  enableTransparency = true;         # Global transparency setting
  opacity = "0.95";                  # Default opacity for transparent backgrounds

  # ============================================================================

  # Select the appropriate theme palette
  themePalettes = {
    gruvbox = gruvbox.variants;
    catppuccin = catppuccin.variants;
    nord = nord.variants;
    onedark = onedark.variants;
    molokai = molokai.variants;
  };

  selectedPalette = themePalettes.${activeTheme}.${activeVariant};

in
{
  inherit themeLib;

  # Theme metadata
  name = activeTheme;
  variant = activeVariant;
  fullName = selectedPalette.name;

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
  };
}
