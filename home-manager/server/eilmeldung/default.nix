{
  inputs,
  config,
  theme,
  ...
}: let
  # Aliased because eilmeldung's own config has a `theme` section, and reading
  # `theme.background` inside `settings.theme` invites a double-take. Plain
  # attrsets are not recursive, so the two never actually collide.
  palette = theme;
in {
  imports = [inputs.eilmeldung.homeManager.default];

  programs.eilmeldung.enable = true;

  # Store feeds.opml for reproducible feed setup
  xdg.configFile."eilmeldung/feeds.opml".source = ./feeds.opml;

  # Wrapper script to auto-import feeds on first run, then launch eilmeldung
  home.file.".local/bin/rss".text = ''
    #!/usr/bin/env bash
    # Auto-import feeds from OPML if database doesn't exist, then launch eilmeldung
    FEEDS_OPML="''${XDG_CONFIG_HOME:-$HOME/.config}/eilmeldung/feeds.opml"
    EILMELDUNG_DB="''${XDG_DATA_HOME:-$HOME/.local/state}/eilmeldung/newsflash.db"

    # Import feeds on first run
    if [ -f "$FEEDS_OPML" ] && [ ! -f "$EILMELDUNG_DB" ]; then
      echo "📡 Importing feeds from OPML..."
      eilmeldung --import-opml "$FEEDS_OPML"
      echo "✅ Feeds imported!"
    fi

    # Launch eilmeldung
    exec eilmeldung "$@"
  '';

  home.file.".local/bin/rss".executable = true;

  programs.eilmeldung.settings = {
    # Auto-sync feeds on startup
    startup_commands = ["sync"];

    # Show all articles (read ones greyed out) instead of unread-only
    article_scope = "all";

    feed_list = [
      "feeds"
      "* categories"
      "tags"
    ];

    # Palette-driven colors, from themes/default.nix, so the reader matches
    # Ghostty/Neovim instead of eilmeldung's ANSI-name defaults (which follow
    # the terminal's 16 slots and so drift whenever one is remapped). Colors are
    # ratatui values: an ANSI name or a hex string. See
    # docs/configuration.md#theme-configuration in the eilmeldung source.
    theme = {
      color_palette = {
        background = palette.background;
        foreground = palette.foreground;
        # `muted` is both dim text and the unfocused border, so it takes the
        # foreground's dimmest step rather than a background grey -- the border
        # is re-pointed at the darker inactiveBorder in style_set below.
        muted = palette.colors.fg4;
        highlight = palette.colors.yellow;
        flagged = palette.colors.red;
        # Accents, in the order eilmeldung uses them: feeds, categories, tags,
        # saved queries.
        accent_primary = palette.activeBorder;
        accent_secondary = palette.colors.blue;
        accent_tertiary = palette.colors.purple;
        accent_quaternary = palette.colors.orange;
        info = palette.colors.blue;
        warning = palette.colors.yellow;
        error = palette.colors.red;
      };

      # Everything else keeps its default, which is expressed in terms of the
      # palette names above and so follows along.
      style_set = {
        border = {fg = palette.inactiveBorder;};
        border_focused = {
          fg = "accent_primary";
          mods = ["bold"];
        };
      };
    };
  };
}
