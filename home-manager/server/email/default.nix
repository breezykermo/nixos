{pkgs, ...}:
let
  # Create typst-editor script and add to PATH
  typst-editor = pkgs.writeShellScriptBin "typst-editor" (builtins.readFile ./typst-editor.sh);

  # Create typst2html wrapper script for multipart conversion
  typst2html = pkgs.writeShellScriptBin "typst2html" ''
    export PATH="${pkgs.typst}/bin:$PATH"
    ${builtins.readFile ./typst2html.sh}
  '';
in {
  # ============================================================================
  # Email Configuration for Aerc
  # ============================================================================
  # This configuration uses home-manager's accounts.email module with the
  # passwordCommand approach for secure credential management.
  #
  # SETUP INSTRUCTIONS:
  # -------------------
  # Before using aerc with this configuration, you need to set up pass (the
  # standard unix password manager):
  #
  # 1. Generate a GPG key (if you don't have one):
  #    $ gpg --full-generate-key
  #    (Follow prompts: choose RSA and RSA, 4096 bits, set expiration, enter your details)
  #
  # 2. Initialize pass with your GPG key ID:
  #    $ pass init "your-email@example.com"
  #    (Use the email associated with your GPG key)
  #
  # 3. Store your email password in pass:
  #    $ pass insert email/gmail
  #    (Enter your email password when prompted)
  #
  # 4. Verify the password is stored correctly:
  #    $ pass show email/personal
  #
  # 5. Update the email account configuration below with your actual:
  #    - Email address
  #    - Username (often same as email address)
  #    - Real name
  #    - IMAP/SMTP server hostnames and ports
  #
  # OPTIONAL: Backup your password store with git-crypt
  # -----------------------------------------------------
  # You can encrypt your ~/.password-store directory with git-crypt for
  # backup purposes, leveraging the existing git-crypt setup in this repo.
  #
  # TYPST EMAIL COMPOSITION WORKFLOW
  # ---------------------------------
  # Aerc is configured to always compose emails in Typst format, with an option
  # to send as HTML from the review screen.
  #
  # WORKFLOW:
  # 1. Compose: Press 'C' or 'm' to compose a new message
  #    - Fill in headers (To, Subject, etc.)
  #    - Editor opens automatically with .typ extension for syntax highlighting
  #
  # 2. Write your email in Typst markup:
  #    ```typst
  #    = Email Title
  #
  #    Hello *name*,
  #
  #    This is a _formatted_ email with:
  #
  #    - Bullet points
  #    - *Bold text*
  #    - _Italics_
  #
  #    Best regards
  #    ```
  #
  # 3. Review: Save and exit editor to reach the review screen
  #
  # 4. Choose format:
  #    - Send as plain Typst: Press 'y' to send as-is (Typst markup as plain text)
  #    - Send as HTML: Press 'h' to convert to HTML, then 'y' to send
  #      (Creates multipart/alternative with both Typst plain + HTML)
  #
  # 5. Preview: Press 'v' to preview the current version
  #
  # 6. Options:
  #    - Press 'y' to send in current format
  #    - Press 'e' to edit again (reopens in Typst)
  #    - Press 'h' to add HTML version
  #    - Press 'n' to abort
  #
  # KEYBINDINGS (in review screen):
  #   h = Add HTML version (creates multipart message)
  #   v = Preview current version
  #   e = Edit (reopens Typst source)
  #   y = Send
  #   n = Abort
  #
  # TECHNICAL DETAILS:
  # - typst-editor.sh: Wrapper that copies temp file to .typ for syntax highlighting
  # - Multipart converter uses Typst → HTML5
  # - When sending with HTML, message contains both Typst (as text/plain) and HTML
  # - Recipients with HTML clients see formatted version, plain text clients see Typst
  #
  # ============================================================================

  home.packages = with pkgs; [
    w3m           # text-based web browser for rendering HTML emails with color support
    libsixel      # provides img2sixel for high-quality sixel image rendering
    urlscan       # extract and open URLs from emails
    poppler-utils # provides pdftotext for PDF conversion
    gnupg         # GPG for encryption (required by pass)
    pinentry-curses  # Terminal-based passphrase entry for GPG
    pass          # password manager for secure credential storage
    typst-editor  # Wrapper script for editing aerc compose files with Typst syntax highlighting
    typst2html    # Wrapper script for converting Typst to HTML via stdin/stdout
  ];

  programs = {
    # GPG configuration for pass
    gpg = {
      enable = true;
    };

    # email in the terminal
    # NOTE: app passwords are per device, generate new ones if using this config
    aerc = {
      enable = true;
      extraConfig = {
        general = {
          unsafe-accounts-conf = true;  # Required for passwordCommand in accounts.email
        };
        ui = {
          sort = "-r date";
          threading-enabled = true;  # Enable threaded view
          force-client-threads = true;  # Use client-side threading
        };
        viewer = {
          always-show-mime = true;
          pager = "less -Rc";  # Support ANSI colors from filters
        };
        compose = {
          format-flowed = true;  # Enable RFC 3676 format=flowed for proper text reflow
          editor = "typst-editor";
        };
        "multipart-converters" = {
          "text/html" = "${typst2html}/bin/typst2html";
        };
        filters = {
          # Render HTML to readable text with color support and numbered links
          # Uses aerc's built-in html filter (network-safe by default)
          # Passes -o display_link_number=1 to w3m for visible link numbers
          "text/html" = "html -o display_link_number=1 | colorize";

          # Plain text with wrapping and colorization
          "text/plain" = "wrap -w 90 | colorize";

          # Show images inline using sixel protocol (high quality)
          "image/*" = "img2sixel -w $(tput cols)";

          # Convert PDFs to text
          "application/pdf" = "pdftotext - -";
        };
      };
      extraBinds = {
        global = {
          "<C-p>" = ":prev-tab<Enter>";
          "<C-PgUp>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
          "<C-PgDn>" = ":next-tab<Enter>";
          "\\[t" = ":prev-tab<Enter>";
          "\\]t" = ":next-tab<Enter>";
          "<C-t>" = ":term<Enter>";
          "?" = ":help keys<Enter>";
          "<C-c>" = ":prompt 'Quit?' quit<Enter>";
          "<C-q>" = ":prompt 'Quit?' quit<Enter>";
          "<C-z>" = ":suspend<Enter>";
        };
        messages = {
          "q" = ":prompt 'Quit?' quit<Enter>";
          "j" = ":next<Enter>";
          "<Down>" = ":next<Enter>";
          "<C-d>" = ":next 50%<Enter>";
          "<C-f>" = ":next 100%<Enter>";
          "<PgDn>" = ":next 100%<Enter>";
          "k" = ":prev<Enter>";
          "<Up>" = ":prev<Enter>";
          "<C-u>" = ":prev 50%<Enter>";
          "<C-b>" = ":prev 100%<Enter>";
          "<PgUp>" = ":prev 100%<Enter>";
          "g" = ":select 0<Enter>";
          "G" = ":select -1<Enter>";
          "J" = ":next-folder<Enter>";
          "<C-Down>" = ":next-folder<Enter>";
          "K" = ":prev-folder<Enter>";
          "<C-Up>" = ":prev-folder<Enter>";
          "H" = ":collapse-folder<Enter>";
          "<C-Left>" = ":collapse-folder<Enter>";
          "L" = ":expand-folder<Enter>";
          "<C-Right>" = ":expand-folder<Enter>";
          "v" = ":mark -t<Enter>";
          "<Space>" = ":mark -t<Enter>:next<Enter>";
          "V" = ":mark -v<Enter>";
          "T" = ":toggle-threads<Enter>";
          "zc" = ":fold<Enter>";
          "zo" = ":unfold<Enter>";
          "za" = ":fold -t<Enter>";
          "zM" = ":fold -a<Enter>";
          "zR" = ":unfold -a<Enter>";
          "<tab>" = ":fold -t<Enter>";
          "zz" = ":align center<Enter>";
          "zt" = ":align top<Enter>";
          "zb" = ":align bottom<Enter>";
          "<Enter>" = ":view<Enter>";
          "d" = ":choose -o y 'Really delete this message' delete-message<Enter>";
          "D" = ":delete<Enter>";
          "a" = ":archive flat<Enter>";
          "A" = ":unmark -a<Enter>:mark -T<Enter>:archive flat<Enter>";
          "C" = ":compose<Enter>";
          "m" = ":compose<Enter>";
          "b" = ":bounce<space>";
          "rr" = ":reply -a<Enter>";
          "rq" = ":reply -aq<Enter>";
          "Rr" = ":reply<Enter>";
          "Rq" = ":reply -q<Enter>";
          "c" = ":cf<space>";
          "$" = ":term<space>";
          "!" = ":term<space>";
          "|" = ":pipe<space>";
          "/" = ":search<space>";
          "\\" = ":filter<space>";
          "n" = ":next-result<Enter>";
          "N" = ":prev-result<Enter>";
          "<Esc>" = ":clear<Enter>";
          "s" = ":split<Enter>";
          "S" = ":vsplit<Enter>";
          "pl" = ":patch list<Enter>";
          "pa" = ":patch apply <Tab>";
          "pd" = ":patch drop <Tab>";
          "pb" = ":patch rebase<Enter>";
          "pt" = ":patch term<Enter>";
          "ps" = ":patch switch <Tab>";
        };
        "messages:folder=Drafts" = {
          "<Enter>" = ":recall<Enter>";
        };
        view = {
          "/" = ":toggle-key-passthrough<Enter>/";
          "q" = ":close<Enter>";
          "O" = ":open<Enter>";
          "o" = ":open<Enter>";
          "S" = ":save<space>";
          "|" = ":pipe<space>";
          "D" = ":delete<Enter>";
          "A" = ":archive flat<Enter>";
          "<C-y>" = ":copy-link <space>";
          "<C-l>" = ":open-link <space>";
          "f" = ":forward<Enter>";
          "rr" = ":reply -a<Enter>";
          "rq" = ":reply -aq<Enter>";
          "Rr" = ":reply<Enter>";
          "Rq" = ":reply -q<Enter>";
          "H" = ":toggle-headers<Enter>";
          "<C-k>" = ":prev-part<Enter>";
          "<C-Up>" = ":prev-part<Enter>";
          "<C-j>" = ":next-part<Enter>";
          "<C-Down>" = ":next-part<Enter>";
          "J" = ":next<Enter>";
          "<C-Right>" = ":next<Enter>";
          "K" = ":prev<Enter>";
          "<C-Left>" = ":prev<Enter>";
          # Extract and open URLs with urlscan
          "u" = ":pipe urlscan<Enter>";
          # Open email in interactive w3m for rich HTML rendering
          "W" = ":pipe ! w3m -I UTF-8 -T text/html<Enter>";
        };
        "view::passthrough" = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<Esc>" = ":toggle-key-passthrough<Enter>";
        };
        compose = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "$complete" = "<C-o>";
          "<C-k>" = ":prev-field<Enter>";
          "<C-Up>" = ":prev-field<Enter>";
          "<C-j>" = ":next-field<Enter>";
          "<C-Down>" = ":next-field<Enter>";
          "<A-p>" = ":switch-account -p<Enter>";
          "<C-Left>" = ":switch-account -p<Enter>";
          "<A-n>" = ":switch-account -n<Enter>";
          "<C-Right>" = ":switch-account -n<Enter>";
          "<tab>" = ":next-field<Enter>";
          "<backtab>" = ":prev-field<Enter>";
          "<C-p>" = ":prev-tab<Enter>";
          "<C-PgUp>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
          "<C-PgDn>" = ":next-tab<Enter>";
        };
        "compose::editor" = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<C-k>" = ":prev-field<Enter>";
          "<C-Up>" = ":prev-field<Enter>";
          "<C-j>" = ":next-field<Enter>";
          "<C-Down>" = ":next-field<Enter>";
          "<C-p>" = ":prev-tab<Enter>";
          "<C-PgUp>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
          "<C-PgDn>" = ":next-tab<Enter>";
        };
        "compose::review" = {
          "y" = ":send<Enter>";
          "n" = ":abort<Enter>";
          "v" = ":preview<Enter>";
          "p" = ":postpone<Enter>";  # Save as draft
          "q" = ":abort<Enter>";
          "e" = ":edit<Enter>";
          "a" = ":attach<space>";
          "d" = ":detach<space>";
          "h" = ":multipart text/html<Enter>";  # Convert from Typst
        };
        terminal = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<C-p>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
          "<C-PgUp>" = ":prev-tab<Enter>";
          "<C-PgDn>" = ":next-tab<Enter>";
        };
      };
    };
  };

  # Email account configuration
  accounts.email.accounts = {
    "brown" = {
      primary = true;
      address = "lachlan_kermode@brown.edu";
      userName = "lachlan_kermode@brown.edu";
      realName = "Lachlan Kermode";

      passwordCommand = "pass show email/brown";

      folders = {
        inbox = "INBOX";
        sent = "[Gmail]/Sent Mail";
      };

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };

      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls = {
          enable = true;
          useStartTls = false;  # Use implicit TLS (smtps://)
        };
      };

      aerc = {
        enable = true;
        extraAccounts = {
          folder-map = "~/.config/aerc/brown-foldermap";
          cache-headers = "true";
        };
      };
    };

    "gmail" = {
      address = "lachiekermode@gmail.com";
      userName = "lachiekermode@gmail.com";
      realName = "Lachie Kermode";

      passwordCommand = "pass show email/gmail";

      folders = {
        inbox = "INBOX";
        sent = "[Gmail]/Sent Mail";
      };

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };

      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls = {
          enable = true;
          useStartTls = false;  # Use implicit TLS (smtps://)
        };
      };

      aerc = {
        enable = true;
        extraAccounts = {
          folder-map = "~/.config/aerc/gmail-foldermap";
          cache-headers = "true";
        };
      };
    };

    "inferstudio" = {
      address = "lachlan@inferstudio.com";
      userName = "lachlan@inferstudio.com";
      realName = "Lachlan Kermode";

      passwordCommand = "pass show email/inferstudio";

      folders = {
        inbox = "INBOX";
      };

      imap = {
        host = "imappro.zoho.eu";
        port = 993;
        tls.enable = true;
      };

      smtp = {
        host = "smtppro.zoho.eu";
        port = 465;
        tls = {
          enable = true;
          useStartTls = false;  # Port 465 uses implicit TLS, not STARTTLS
        };
      };

      aerc = {
        enable = true;
        extraAccounts = {
          cache-headers = "true";
        };
      };
    };
  };

  # Folder-map files for Gmail accounts to remove [Gmail]/ prefix
  xdg.configFile."aerc/brown-foldermap".text = ''
    * = [Gmail]/*
  '';

  xdg.configFile."aerc/gmail-foldermap".text = ''
    * = [Gmail]/*
  '';

  # GPG Agent configuration for pinentry
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };
}
