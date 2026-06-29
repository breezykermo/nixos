{ inputs, config, ... }:
{
  imports = [ inputs.eilmeldung.homeManager.default ];

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
    startup_commands = [ "sync" ];

    # Show all articles (read ones greyed out) instead of unread-only
    article_scope = "all";

    feed_list = [
      "feeds"
      "* categories"
      "tags"
    ];
  };
}
