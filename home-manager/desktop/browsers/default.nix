# Adapted from 
# https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265
{ pkgs, ... }:
let
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
in
{
  home.packages = with pkgs; [
    brave
  ];

  programs.chromium.enable = true;

  programs.firefox = {
    enable = true;
    profiles = {
      default = {
        id = 0;
        name = "default";
        search = {
          force = true;
          default = "Kagi";
          engines = {
            "Kagi" = {
              urls = [{
                template = "https://kagi.com/search?";
                params = [{ name = "q"; value = "{searchTerms}"; }];
              }];
              definedAliases = [ "@kg" ];
            };
            "wikipedia".metaData.alias = "@wiki";
            "google".metaData.hidden = true;
            "amazondotcom-us".metaData.hidden = true;
            "bing".metaData.hidden = true;
            "ebay".metaData.hidden = true;
          };
        };
        settings = {
          "gfx.webrender.all" = true; # Force enable GPU acceleration
          "media.ffmpeg.vaapi.enabled" = true;
          "widget.dmabuf.force-enabled" = true; # Required in recent Firefoxes

          "extensions.pocket.enabled" = false;
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_ever_enabled" = true;
        };
        extraConfig = ''
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("full-screen-api.ignore-widgets", true);
        user_pref("media.ffmpeg.vaapi.enabled", true);
        user_pref("media.rdd-vpx.enabled", true);
        '';

        userChrome = builtins.readFile ./userChrome.css;
        
        bookmarks = {
		force = true;
		settings = [
		  {
		    name = "Wikipedia";
		    tags = [ "wiki" ];
		    keyword = "wiki";
		    url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
		  }
		  # Brown
		  {
		    name = "[m]ail [b]rown";
		    tags = [];
		    keyword = "mb";
		    url = "https://mail.google.com/mail/u/0/#inbox";
		  }
		  {
		    name = "[c]alendar [b]rown";
		    tags = [];
		    keyword = "cb";
		    url = "https://calendar.google.com/calendar/u/0/r";
		  }
		  {
		    name = "[d]rive [b]rown";
		    tags = [];
		    keyword = "db";
		    url = "https://drive.google.com/drive/u/0/my-drive";
		  }

		  # Personal 
		  {
		    name = "[m]ail [p]ersonal";
		    tags = [];
		    keyword = "mp";
		    url = "https://mail.google.com/mail/u/1/#inbox";
		  }
		  {
		    name = "[c]alendar [p]ersonal";
		    tags = [];
		    keyword = "cp";
		    url = "https://calendar.google.com/calendar/u/1/r";
		  }
		  {
		    name = "[d]rive [p]ersonal";
		    tags = [];
		    keyword = "dp";
		    url = "https://drive.google.com/drive/u/1/my-drive";
		  }

		  # Ohrg 
		  {
		    name = "[m]ail [o]hrg";
		    tags = [];
		    keyword = "mo";
		    url = "https://mail.proton.me/u/0/inbox";
		  }
		  {
		    name = "[c]alendar [o]hrg";
		    tags = [];
		    keyword = "co";
		    url = "https://calendar.proton.me/u/0/";
		  }

		  # Hotmail 
		  {
		    name = "[m]ail [h]otmail";
		    tags = [];
		    keyword = "mh";
		    url = "https://outlook.live.com/mail/0/";
		  }

      # Inferstudo
      {
        name = "[m]ail [i]nferstudo";
        tags = [];
        keyword = "mi";
        url = "https://mail.zoho.eu/zm/#mail/folder/inbox";
      }

      # Unibo
            # https://outlook.office.com/mail/0/?culture=en-us&country=us
      {
        name = "[m]ail [u]nibo";
        tags = [];
        keyword = "mu";
        url = "https://outlook.office.com/mail/0/?culture=en-us&country=us";
      }
      {
        name = "[c]alendar [u]nibo";
        tags = [];
        keyword = "cu";
        url = "https://outlook.office.com/calendar/0/view/month?culture=en-us&country=us";
      }

		  # LLMs
		  {
		    name = "[ai] [c]laude";
		    tags = [];
		    keyword = "aic";
		    url = "https://claude.ai/new";
		  }
		  {
		    name = "[ai] [k]agi";
		    tags = [];
		    keyword = "aik";
		    url = "https://kagi.com/assistant";
		  }
		  {
		    name = "[ai] chat [g]pt";
		    tags = [];
		    keyword = "aig";
		    url = "https://chatgpt.com/";
		  }

		  # Other 
		  {
		    name = "[g]it[h]ub";
		    tags = [];
		    keyword = "gh";
		    url = "https://github.com";
		  }
		  {
		    name = "[d]i[s]cord";
		    tags = [];
		    keyword = "ds";
		    url = "https://discord.com/channels/@me";
		  }
		  {
		    name = "[w]hatsap[p]";
		    tags = [];
		    keyword = "wp";
		    url = "https://web.whatsapp.com/";
		  }
		  {
		    name = "[ne]tlify";
		    tags = [];
		    keyword = "ne";
		    url = "https://app.netlify.com/teams/breezykermo/sites/";
		  }
		];
	};
      };
    };

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value= true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
      DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
      SearchBar = "unified"; # alternative: "separate"

      /* ---- EXTENSIONS ---- */
      # Check about:support for extension/add-on ID strings.
      # To get new values:
      # - Disable blocked installation mode by uncommenting below
      # - install https://github.com/mkaply/queryamoid/releases/tag/v0.1
      # - go to https://addons.mozilla.org and click the addon to get ID and install_url

      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      ExtensionSettings = {
        "*".installation_mode = "allowed"; # blocks all addons except the ones specified below
        # uBlock Origin:
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        # Privacy Badger:
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          installation_mode = "force_installed";
        };
        # Proton Pass:
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
          installation_mode = "force_installed";
        };
        # Dark Reader:
        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };
        # Vimium:
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
          installation_mode = "force_installed";
        };
        # ProtonVPN
        "vpn@proton.ch" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-vpn-firefox-extension/latest.xpi";
          installation_mode = "force_installed";
        };
        # Zotero
      };

      /* ---- PREFERENCES ---- */
      # Check about:config for options.
      Preferences = { 
        "layout.css.light-dark.enabled" = lock-true;
        "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
        "extensions.pocket.enabled" = lock-false;
        "extensions.screenshots.disabled" = lock-true;
        "browser.topsites.contile.enabled" = lock-false;
        "browser.formfill.enable" = lock-false;
        "browser.urlbar.suggest.history" = lock-false;
        "browser.urlbar.shortcuts.history" = lock-false;
        "browser.download.clearHistoryOnDelete" = lock-true;
        "browser.search.openintab" = lock-true;
        "browser.search.suggest.enabled" = lock-false;
        "browser.search.suggest.enabled.private" = lock-false;
        "browser.urlbar.suggest.searches" = lock-false;
        "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
      };
    };
  };
}

