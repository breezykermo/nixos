# Aerc Configuration with Sensitive Data - Options and Recommendations

## Context

The user has an `accounts.conf` file in `~/.config/aerc` that contains sensitive information (passwords) and doesn't want to store it in the NixOS configuration as plain text. Currently, they manually copy this file from a stored location after installation.

## Problem

Home-manager's `programs.aerc` will manage the entire `~/.config/aerc/` directory by creating symlinks to read-only files in `/nix/store`. This creates two issues:
1. The symlinked files are world-readable (permissions 0444)
2. Home-manager may overwrite the manually maintained `accounts.conf`

## Research Findings

### How Home-Manager Handles Aerc

- Uses `xdg.configFile` which creates symlinks from `~/.config/aerc/` to `/nix/store`
- Files in `/nix/store` are read-only and world-readable
- The current configuration only manages UI settings and filters, not accounts
- There's a TODO comment noting that "app passwords are per device"

### Existing Patterns in the Codebase

- **git-crypt**: Already set up for encrypting `secrets/**` directory
- **secrets/secrets.json**: Exists but not currently used in home-manager config
- No existing examples of using `accounts.email` module or `passwordCommand`

## Proposed Solutions

### Option 1: Use `passwordCommand` (RECOMMENDED) ⭐

**Security: ⭐⭐⭐⭐⭐ | Declarative: ⭐⭐⭐⭐⭐ | Complexity: ⭐⭐⭐**

Use home-manager's `accounts.email` module with `passwordCommand` to retrieve passwords from a password manager (like `pass`).

**Implementation:**

```nix
# home-manager/server/email/default.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    lynx
    chafa
    poppler_utils
    pass  # password manager
  ];

  programs.aerc = {
    enable = true;
    extraConfig = {
      general = {
        unsafe-accounts-conf = true;  # Required for passwordCommand
      };
      ui = { sort = "-r date"; };
      filters = {
        "text/html" = "lynx -stdin -dump -width 100";
        "image/*" = "chafa -";
        "application/pdf" = "pdftotext - -";
        "*/*" = "xdg-open";
      };
    };
  };

  accounts.email.accounts = {
    "personal" = {
      address = "your-email@example.com";
      userName = "your-username";
      realName = "Your Name";

      # Password retrieved via command, NOT stored in nix store
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
          check-mail-cmd = "mbsync personal";
        };
      };
    };
  };
}
```

**Setup steps:**
1. Generate GPG key if needed: `gpg --gen-key`
2. Initialize pass: `pass init "your-gpg-id"`
3. Store passwords: `pass insert email/personal`
4. Optionally encrypt the `~/.password-store` directory with git-crypt for backup

**Pros:**
- Passwords never stored in nix store
- Fully declarative and version-controlled
- Standard NixOS/home-manager pattern
- Works with any password manager (pass, 1password, bitwarden-cli, etc.)

**Cons:**
- Requires setting up a password manager
- Needs `unsafe-accounts-conf = true` flag (ironic name, but necessary)

---

### Option 2: Store Encrypted accounts.conf in git-crypt

**Security: ⭐⭐ | Declarative: ⭐⭐⭐ | Complexity: ⭐⭐**

Store `accounts.conf` in the `secrets/` directory (encrypted by git-crypt) and copy it via home-manager.

**Implementation:**

```nix
# home-manager/server/email/default.nix
{pkgs, ...}: {
  home.packages = with pkgs; [lynx chafa poppler_utils];

  programs.aerc = {
    enable = true;
    extraConfig = {
      general = {
        unsafe-accounts-conf = true;
      };
      ui = { sort = "-r date"; };
      filters = {
        "text/html" = "lynx -stdin -dump -width 100";
        "image/*" = "chafa -";
        "application/pdf" = "pdftotext - -";
        "*/*" = "xdg-open";
      };
    };
  };

  # Copy encrypted accounts.conf from secrets directory
  xdg.configFile."aerc/accounts.conf".source = ../../secrets/aerc-accounts.conf;
}
```

Store the actual accounts.conf in `/etc/nixos/secrets/aerc-accounts.conf`.

**Pros:**
- Uses existing git-crypt infrastructure
- Simple to understand
- Passwords encrypted in git repository

**Cons:**
- **SECURITY ISSUE**: File ends up in `/nix/store` world-readable after decryption
- Not recommended for production use
- Aerc will warn about permissions

---

### Option 3: Manual accounts.conf + Selective Home-Manager (CURRENT APPROACH)

**Security: ⭐⭐⭐⭐ | Declarative: ⭐ | Complexity: ⭐**

Keep the current manual approach but document it properly.

**Implementation:**

```nix
# home-manager/server/email/default.nix
{pkgs, ...}: {
  home.packages = with pkgs; [lynx chafa poppler_utils];

  programs.aerc = {
    enable = true;
    extraConfig = {
      ui = { sort = "-r date"; };
      filters = {
        "text/html" = "lynx -stdin -dump -width 100";
        "image/*" = "chafa -";
        "application/pdf" = "pdftotext - -";
        "*/*" = "xdg-open";
      };
    };
  };

  # NOTE: accounts.conf is managed manually in ~/.config/aerc/accounts.conf
  # with proper permissions (0600) to keep passwords secure.
  # Do not add accounts.email configuration here to avoid conflicts.
}
```

Manually maintain `~/.config/aerc/accounts.conf` outside of home-manager.

**Pros:**
- Complete control over accounts.conf
- Can set proper permissions (0600)
- Passwords never touch nix store
- Simple and straightforward

**Cons:**
- Not declarative
- Manual setup required on each machine
- Home-manager might still interfere with some files
- Risk of overwriting on updates

---

### Option 4: Use mkOutOfStoreSymlink for Mutable Config

**Security: ⭐⭐⭐⭐ | Declarative: ⭐⭐ | Complexity: ⭐⭐⭐⭐**

Create a symlink outside the nix store to allow mutable configuration.

**Implementation:**

```nix
{pkgs, config, ...}: {
  programs.aerc = {
    enable = true;
    extraConfig = {
      ui = { sort = "-r date"; };
      filters = {
        "text/html" = "lynx -stdin -dump -width 100";
        "image/*" = "chafa -";
        "application/pdf" = "pdftotext - -";
        "*/*" = "xdg-open";
      };
    };
  };

  xdg.configFile."aerc/accounts.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "/home/lox/.config/aerc/accounts.conf.local";
  };
}
```

Maintain `~/.config/aerc/accounts.conf.local` manually with proper permissions.

**Pros:**
- Allows mutable configuration
- Proper file permissions possible
- Home-manager won't overwrite the target file

**Cons:**
- Breaks pure declarative model
- More complex setup
- Need to manually maintain the local file
- Symlink indirection can be confusing

---

## Comparison Table

| Approach | Security | Declarative | Complexity | Recommendation |
|----------|----------|-------------|------------|----------------|
| passwordCommand | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | **Best choice** |
| git-crypt | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | Not recommended |
| Manual config | ⭐⭐⭐⭐ | ⭐ | ⭐ | Acceptable |
| mkOutOfStoreSymlink | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | Overly complex |

## Recommendation

**Option 1 (passwordCommand with pass)** is the recommended approach because:
1. Most secure - passwords never stored in nix store
2. Fully declarative and version-controlled
3. Standard NixOS/home-manager pattern
4. Can leverage existing git-crypt for the password store itself

**Alternative:** If you prefer to keep manual control and avoid setting up a password manager, **Option 3** (current manual approach) is acceptable. Just ensure you document it clearly in the configuration file.

## Next Steps

Choose one of the options above and I can help implement it. The implementation will:
1. Update `/etc/nixos/home-manager/server/email/default.nix` with the chosen approach
2. Add any necessary documentation or setup instructions
3. Test that home-manager doesn't overwrite the manual config (if choosing Option 3)
