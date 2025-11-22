# Theming System

This NixOS configuration uses a centralized theming system that allows you to easily switch color schemes across all applications.

## Quick Start

To change your theme, edit `/etc/nixos/themes/default.nix` and modify these variables:

```nix
activeTheme = "gruvbox";           # Options: "gruvbox", "catppuccin", "nord", "onedark", "molokai"
activeVariant = "dark-hard";       # See variant options below for each theme
enableTransparency = true;         # Global transparency setting
opacity = "0.95";                  # Default opacity for transparent backgrounds
```

**Variant Options by Theme:**
- Gruvbox: `dark-hard`, `dark-medium`, `dark-soft`, `dark-pale`
- Catppuccin: `mocha`, `macchiato`, `frappe`, `latte`
- Nord: `polar-night`, `snow-storm`, `frost`, `aurora`
- OneDark: `dark`, `darker`, `vivid`, `light`
- Molokai: `classic`, `phoenix`, `vivid`, `dark`

Then run `just deploy` to apply the changes.

## Available Themes

### Gruvbox

A retro groove color scheme with warm, earthy tones.

**Variants:**
- `dark-hard` - Darkest variant with highest contrast (#1d2021 background)
- `dark-medium` - Medium contrast variant (#282828 background) - Standard Gruvbox
- `dark-soft` - Softest contrast variant (#32302f background)
- `dark-pale` - Pale variant with muted colors (#262626 background)

**Current default:** `gruvbox` with `dark-hard` variant

### Catppuccin

A modern, soothing pastel theme.

**Variants:**
- `mocha` - Dark theme with warm tones
- `macchiato` - Dark theme with cooler tones
- `frappe` - Dark theme with purple accents
- `latte` - Light theme (only light variant available)

### Nord

A arctic, north-bluish color palette with a clean and elegant look.

**Variants:**
- `polar-night` - Main dark variant using Polar Night backgrounds (default)
- `snow-storm` - Light variant with Snow Storm backgrounds
- `frost` - Blue-tinted variant emphasizing Frost colors
- `aurora` - Warm variant emphasizing Aurora colors (red, orange, yellow, green, purple)

**Color scheme:** Based on four named color palettes - Polar Night (dark), Snow Storm (light), Frost (blue), and Aurora (vibrant accents)

### One Dark

The iconic Atom editor theme - a balanced dark color scheme.

**Variants:**
- `dark` - Classic One Dark (standard background)
- `darker` - Darker backgrounds for reduced eye strain
- `vivid` - More saturated, vibrant colors
- `light` - Light variant for daytime use

**Characteristics:** Well-balanced colors, excellent for long coding sessions, widely supported

### Molokai

A Vim port of the Monokai theme with vibrant, high-contrast colors.

**Variants:**
- `classic` - Original Molokai with very dark backgrounds and vibrant accents
- `phoenix` - Warmer variant with brown-tinted backgrounds
- `vivid` - Extremely saturated colors for maximum contrast
- `dark` - Pure black backgrounds with less saturated colors

**Characteristics:** High contrast, vibrant colors, excellent syntax differentiation

## Applications Using Theme System

The following applications automatically use your configured theme:

### Terminal & Shell
- **Ghostty** - Terminal emulator (background color, opacity)
- **Tmux** - Terminal multiplexer (status bar, borders, mode colors)
- **Bat** - Syntax highlighting for `cat` (native theme support)
- **LS_COLORS** - Directory listing colors (via vivid)
- **FZF** - Fuzzy finder colors

### Window Manager & Desktop
- **Hyprland** - Window manager borders (active/inactive)
- **Rofi** - Application launcher (native theme support)

### Development Tools
- **Neovim** - Editor colorscheme (gruvbox-dark-hard)
- **Lualine** - Neovim statusline (gruvbox theme)
- **ftdv** - File tree diff viewer (complete color mapping)

## Theme Structure

### File Organization

```
themes/                # Top-level directory (same level as fonts/, machines/)
├── default.nix       # Active theme selector (EDIT THIS to switch themes)
├── gruvbox.nix       # Gruvbox color definitions
├── catppuccin.nix    # Catppuccin color definitions
└── lib.nix           # Helper functions for color manipulation
```

### Color Palette

Each theme variant provides the following colors:

**Background layers:**
- `bg0_hard` - Hardest/darkest background
- `bg0` - Normal background
- `bg1` - Lighter background
- `bg2`, `bg3`, `bg4` - Progressively lighter backgrounds

**Foreground layers:**
- `fg0` - Primary foreground (text)
- `fg1` - Secondary foreground
- `fg2`, `fg3`, `fg4` - Progressively dimmer foregrounds

**Accent colors:**
- `red`, `green`, `yellow`, `blue`, `purple`, `aqua`, `orange`, `gray`
- `bright_*` variants for each color

### Convenient Aliases

The theme system provides convenient aliases in `default.nix`:

```nix
background       # Maps to bg0_hard
backgroundAlt    # Maps to bg1
foreground       # Maps to fg0
foregroundAlt    # Maps to fg1

activeBorder     # Maps to aqua
inactiveBorder   # Maps to bg3

success          # Maps to green
warning          # Maps to yellow
error            # Maps to red
info             # Maps to blue
```

## Using Theme in Your Configs

To use the theme system in a new Nix module:

1. **Import the theme:**

```nix
{ pkgs, lib, ... }:
let
  # Import path depends on file location:
  # - From home-manager/*.nix: ../../themes/default.nix
  # - From home-manager/server/*.nix or home-manager/desktop/*.nix: ../../themes/default.nix
  # - From home-manager/server/app/*.nix or home-manager/desktop/app/*.nix: ../../../themes/default.nix
  theme = import ../../themes/default.nix { inherit lib; };
in
{
  # Your configuration here
}
```

2. **Use theme colors:**

```nix
# Direct color access
programs.myapp.backgroundColor = theme.background;
programs.myapp.foregroundColor = theme.foreground;

# Access specific palette colors
programs.myapp.errorColor = theme.colors.red;
programs.myapp.successColor = theme.colors.green;

# Use theme name for apps with native theme support
programs.myapp.theme = theme.fullName;  # e.g., "gruvbox-dark-hard"
```

3. **Generate config files with theme colors:**

```nix
xdg.configFile."myapp/config".text = ''
  background = ${theme.background}
  foreground = ${theme.foreground}
  accent = ${theme.colors.aqua}
'';
```

## Helper Functions

The theme system provides helper functions for color manipulation:

```nix
# Convert hex to rgba with custom alpha
theme.helpers.toRgba "#ff0000" "0.8"  # => "rgba(255, 0, 0, 0.8)"

# Convert to Hyprland rgba format
theme.helpers.toHyprRgba "#ff0000" "aa"  # => "rgba(ff0000aa)"

# Apply theme opacity to a color
theme.helpers.withOpacity "#ff0000"  # Uses theme.transparency.opacity
```

## Adding a New Theme

To add a new theme (e.g., "nord"):

1. Create `themes/nord.nix` with color definitions:

```nix
{ lib }:

{
  variants = {
    dark = {
      name = "nord";

      # Define all required colors
      bg0_hard = "#2e3440";
      bg0 = "#3b4252";
      # ... (continue with all colors)
    };
  };
}
```

2. Import it in `themes/default.nix`:

```nix
let
  nord = import ./nord.nix { inherit lib; };

  themePalettes = {
    gruvbox = gruvbox.variants;
    catppuccin = catppuccin.variants;
    nord = nord.variants;  # Add your theme here
  };
in
```

3. Set `activeTheme = "nord"` and `activeVariant = "dark"` in `default.nix`

## Transparency Settings

Global transparency is controlled by:

```nix
enableTransparency = true;   # Master switch
opacity = "0.95";            # Default opacity value
```

Access in your configs:

```nix
theme.transparency.enabled        # true/false
theme.transparency.opacity        # "0.95" (string)
theme.transparency.opacityFloat   # 0.95 (float)
```

Currently used in:
- Ghostty terminal background
- Neovim background (hardcoded transparent)
- Tmux status bar (transparent background)

## Troubleshooting

### Theme not applying after rebuild

1. Make sure you ran `just deploy` after editing `themes/default.nix`
2. Restart the affected application (some apps cache themes)
3. For Neovim changes, restart Neovim (the colorscheme is loaded at startup)

### Colors look wrong

1. Verify your terminal supports true color (24-bit color)
2. Check that the theme variant is spelled correctly
3. Ensure the application supports the color format being used

### Application not using theme

Some applications may need:
- Explicit restart after deployment
- Cache clearing (e.g., `~/.cache/nvim`)
- Manual theme activation (rare)

## Future Enhancements

Potential improvements to the theme system:

1. **GTK/Qt theme integration** - Extend theming to GUI applications
2. **Automatic Neovim theme generation** - Generate lua theme file from Nix colors
3. **Dark/light mode toggle** - Quick switch between dark and light variants
4. **Per-application theme overrides** - Allow specific apps to use different themes
5. **Theme preview tool** - Generate screenshots/previews of themes before applying

## Theme Quick Reference

| Theme | Best For | Variants | Characteristics |
|-------|----------|----------|-----------------|
| **Gruvbox** | All-around use, warm aesthetic | 4 variants (3 dark + 1 pale) | Retro, warm, earthy tones |
| **Catppuccin** | Modern aesthetic, pastel lovers | 4 variants (3 dark + 1 light) | Soothing, pastel colors |
| **Nord** | Clean look, blue lovers | 4 variants (2 dark + 2 special) | Arctic, bluish, elegant |
| **One Dark** | Long coding sessions | 4 variants (3 dark + 1 light) | Balanced, Atom-inspired |
| **Molokai** | High contrast work | 4 variants (all dark) | Vibrant, high contrast |

### Popular Theme Combinations

**For Productivity:**
- Nord polar-night (clean and focused)
- One Dark dark (balanced and calm)
- Gruvbox dark-medium (comfortable)

**For Coding:**
- Molokai classic (excellent syntax differentiation)
- One Dark vivid (vibrant but balanced)
- Gruvbox dark-hard (high contrast)

**For Aesthetics:**
- Catppuccin mocha (modern and pretty)
- Nord aurora (colorful accents)
- Molokai phoenix (warm and unique)

**Light Themes:**
- Catppuccin latte (best light theme)
- One Dark light (familiar for Atom users)
- Nord snow-storm (arctic light)

## References

- [Gruvbox](https://github.com/morhetz/gruvbox) - Original Gruvbox theme
- [Catppuccin](https://github.com/catppuccin/catppuccin) - Catppuccin theme project
- [Nord](https://www.nordtheme.com) - Nord theme official website
- [One Dark](https://github.com/atom/one-dark-syntax) - Atom One Dark theme
- [Molokai](https://github.com/tomasr/molokai) - Molokai for Vim
- [base16](https://github.com/chriskempson/base16) - Base16 color scheme framework
