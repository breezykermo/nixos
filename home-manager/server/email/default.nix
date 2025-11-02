{pkgs, ...}: {
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
  #    $ pass insert email/personal
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
  # ============================================================================

  home.packages = with pkgs; [
    lynx          # text-based web browser for rendering HTML emails
    chafa         # terminal graphics, for displaying images inline
    poppler_utils # provides pdftotext for PDF conversion
    gnupg         # GPG for encryption (required by pass)
    pinentry-curses  # Terminal-based passphrase entry for GPG
    pass          # password manager for secure credential storage
  ];

  programs = {
    # GPG configuration for pass
    gpg = {
      enable = true;
    };

    # email in the terminal
    # NOTE: app passwords are per device, generate new ones if using this config
    # TODO: [compose] format-flowed=true
    # as currently this is just in my local config.
    aerc = {
      enable = true;
      extraConfig = {
        general = {
          unsafe-accounts-conf = true;  # Required for passwordCommand in accounts.email
        };
        ui = { sort = "-r date"; };
        filters = {
          # Render HTML to readable text
          "text/html" = "lynx -stdin -dump -width 100";

          # Show images inline as ANSI
          "image/*" = "chafa -";

          # Convert PDFs to text
          "application/pdf" = "pdftotext - -";

          # Fallback: open anything else externally
          "*/*" = "xdg-open";
        };
      };
    };
  };

  # Email account configuration
  # TODO: Replace placeholder values with your actual email account details
  accounts.email.accounts = {
    "personal" = {
      primary = true;  # Required: designate as primary account
      address = "your-email@example.com";
      userName = "your-username";
      realName = "Your Name";

      # Password retrieved via pass command (never stored in nix store)
      # Make sure to run: pass insert email/personal
      passwordCommand = "pass show email/personal";

      imap = {
        host = "imap.example.com";
        port = 993;
        tls.enable = true;
      };

      smtp = {
        host = "smtp.example.com";
        port = 587;
        tls.enable = true;
      };

      aerc = {
        enable = true;
        extraAccounts = {
          # Optional: configure mail sync command
          # check-mail-cmd = "mbsync personal";
        };
      };
    };
  };

  # GPG Agent configuration for pinentry
  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };
}
