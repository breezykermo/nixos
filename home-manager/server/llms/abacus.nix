{
  lib,
  buildGoModule,
  fetchFromGitHub,
  theme,
}: let
  # abacus's themes are compiled-in Go structs registered in
  # internal/ui/theme/*.go -- there is no config-file hook for a custom palette
  # (internal/ui/theme/manager.go only ever reads its in-process registry). So
  # the active palette from themes/default.nix is emitted as one more theme
  # source file and dropped into that package before the build.
  #
  # Called `system` for the same reason tuicr's, pi's and Claude Code's
  # generated themes are: it follows whatever themes/default.nix has active, so
  # switching palettes needs no rename here or in any config file.
  #
  # abacus asks lipgloss for AdaptiveColor (a Dark/Light pair chosen from the
  # terminal's detected background). Our palettes are dark-only, so both halves
  # get the same hex -- correct on this machine's terminals, and no worse than
  # guessing at light variants that the palette does not define.
  adaptive = color: ''lipgloss.AdaptiveColor{Dark: "${color}", Light: "${color}"}'';
  method = name: color: ''
    func (t SystemTheme) ${name}() lipgloss.AdaptiveColor {
    	return ${adaptive color}
    }
  '';
  systemThemeGo =
    ''
      package theme

      import "github.com/charmbracelet/lipgloss"

      // SystemTheme is generated from the active palette in
      // /etc/nixos/themes/default.nix (currently ${theme.fullName}) by
      // home-manager/server/llms/abacus.nix. Do not expect it upstream.
      type SystemTheme struct{}

    ''
    + lib.concatStrings [
      # Accents: focused borders and header background, then field labels and
      # links, then issue IDs and titles.
      (method "Primary" theme.colors.aqua)
      (method "Secondary" theme.colors.blue)
      (method "Accent" theme.colors.purple)

      # Status.
      (method "Error" theme.colors.red)
      (method "Warning" theme.colors.yellow)
      (method "Success" theme.colors.green)
      (method "Info" theme.colors.blue)

      # Text.
      (method "Text" theme.foreground)
      (method "TextMuted" theme.colors.fg3)
      (method "TextEmphasized" theme.colors.yellow)

      # Surfaces: main background, selected rows, then chips and badges.
      (method "Background" theme.background)
      (method "BackgroundSecondary" theme.colors.bg2)
      (method "BackgroundDarker" theme.colors.bg0)

      # Borders.
      (method "BorderNormal" theme.inactiveBorder)
      (method "BorderFocused" theme.activeBorder)
      (method "BorderDim" theme.colors.bg1)
    ]
    + ''

      func init() {
      	RegisterTheme("system", SystemTheme{})
      }
    '';
in
  buildGoModule rec {
    pname = "abacus";
    version = "0.11.2";

    src = fetchFromGitHub {
      owner = "ChrisEdwards";
      repo = "abacus";
      rev = "main";
      hash = "sha256-HuHSmpquBRk3qZZm/CZv7cEPF3QmTZZ9/ipX8ODDMlA=";
    };

    vendorHash = "sha256-pZJA8TiYGlMMgH7JPiH+WUN7hNoL9wo/NWL9g+KhUL8=";

    # Add the generated theme, then make it the default. Patching the viper
    # default (rather than writing `theme:` into ~/.abacus/config.yaml) keeps it
    # a DEFAULT: abacus persists a theme picked at runtime with `t`/`T` into
    # that file, and a persisted choice still wins over this.
    postPatch = ''
      cp ${builtins.toFile "abacus-system-theme.go" systemThemeGo} \
        internal/ui/theme/system.go
      substituteInPlace internal/config/config.go \
        --replace-fail 'v.SetDefault(KeyTheme, "tokyonight")' \
                       'v.SetDefault(KeyTheme, "system")'
    '';

    ldflags = [
      "-s"
      "-w"
    ];

    subPackages = ["cmd/abacus"];

    meta = with lib; {
      description = "Terminal UI for visualizing and navigating Beads issue tracking projects";
      homepage = "https://github.com/ChrisEdwards/abacus";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "abacus";
    };
  }
