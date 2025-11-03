# Email Contact Autocomplete for Aerc

This document explores different approaches to implementing contact autocomplete in aerc, particularly in the context of IMAP-only vs maildir-based email setups.

## Table of Contents
1. [Overview](#overview)
2. [maildir-rank-addr (Original Goal)](#maildir-rank-addr-original-goal)
3. [IMAP-Compatible Alternatives](#imap-compatible-alternatives)
4. [Feature Comparison](#feature-comparison)
5. [NixOS Implementation Details](#nixos-implementation-details)
6. [Recommendations](#recommendations)

---

## Overview

Aerc supports contact autocomplete via the `address-book-cmd` configuration option. When you press Tab while composing an email in the To/Cc/Bcc fields, aerc runs this command with your partial input and displays the results as completion options.

### The Challenge

Our current aerc setup uses **direct IMAP connections** (`source = imaps://...`), which only cache email headers locally in LevelDB format. Many contact autocomplete tools, including the excellent `maildir-rank-addr`, require **local maildir storage** where actual email files are stored on disk.

### Available Approaches

1. **Switch to maildir with mbsync** - Enables maildir-rank-addr with automatic ranking
2. **Use CardDAV sync (khard + vdirsyncer)** - Works with IMAP-only, syncs existing contacts
3. **Simple TSV file** - Manual but works immediately with any setup
4. **Semi-automated tools** - Middle ground between manual and automatic

---

## maildir-rank-addr (Original Goal)

**Repository**: https://github.com/ferdinandyb/maildir-rank-addr
**Package**: Available in nixpkgs as `maildir-rank-addr` (version 1.4.1)

### What It Does

maildir-rank-addr automatically generates a ranked contact list by scanning local email files. It's the gold standard for email-based contact autocomplete:

- **Scans email headers**: To, Cc, Bcc, From, Sender, Reply-To fields
- **Intelligent ranking** based on:
  - **Classification**: People you've emailed directly (Class 2) > CC'd (Class 1) > received from (Class 0)
  - **Frequency**: How often you correspond
  - **Recency**: Recent contacts rank higher
- **Performance**: Processes 270,000 emails in ~7 seconds
- **Output**: Tab-separated values (TSV) file for fast searching

### Why It Requires Maildir

maildir-rank-addr needs to parse actual email message files to extract contact information. Our current IMAP setup only stores:
- Email headers in a LevelDB cache (for threading/UI)
- No complete message bodies locally

To use maildir-rank-addr, we would need to:
1. Configure mbsync to download all emails locally
2. Point aerc at the local maildir instead of IMAP
3. Keep emails synchronized between server and local storage

### Pros and Cons

**Pros**:
- ✅ Fully automatic contact discovery
- ✅ Intelligent ranking by frequency and recency
- ✅ Zero maintenance after initial setup
- ✅ Filters noreply addresses automatically
- ✅ Works offline
- ✅ Fast performance

**Cons**:
- ❌ Requires switching from IMAP to maildir
- ❌ Uses local disk space (all emails stored locally)
- ❌ Requires mbsync setup and ongoing sync
- ❌ Initial sync can take time for large mailboxes

### How It Would Work

1. User types: `To: john.s` and presses Tab
2. Aerc runs: `ugrep -jP -m 100 --color=never "john.s" ~/.cache/maildir-rank-addr/addressbook.tsv`
3. Results returned: `john.smith@example.com	John Smith`
4. Ranked by how often you email John

---

## IMAP-Compatible Alternatives

These solutions work with the current IMAP-only setup without requiring local email storage.

### 1. khard + vdirsyncer (CardDAV Sync)

**Type**: Contact manager with CardDAV synchronization
**Packages**: `khard`, `vdirsyncer` (both in nixpkgs)
**Autocomplete Quality**: ⭐⭐⭐⭐ (Very Good)

#### How It Works

```
CardDAV Server → vdirsyncer → Local .vcf files → khard → aerc autocomplete
(Google/iCloud)   (syncs)     (~/.contacts/)    (searches)
```

1. **vdirsyncer** syncs contacts from CardDAV servers (Google Contacts, iCloud, Nextcloud, Fastmail, etc.) to local vCard (.vcf) files
2. **khard** reads these local files and provides fast contact searching
3. Aerc calls khard for autocomplete
4. Completely independent of email backend (works with any IMAP setup)

#### Setup Steps

**Required Services**:
- CardDAV server (Gmail/Brown have Google Contacts, most providers offer this)

**Configuration**:
1. vdirsyncer config: `~/.config/vdirsyncer/config`
2. khard config: `~/.config/khard/khard.conf`
3. Aerc config: `address-book-cmd = khard email --remove-first-line --parsable '%s'`
4. Systemd timer for automatic hourly sync

**Initial Commands**:
```bash
vdirsyncer discover
vdirsyncer sync
khard list  # Verify contacts loaded
```

#### Pros and Cons

**Pros**:
- ✅ Works perfectly with IMAP-only setup
- ✅ No local mail storage required
- ✅ Syncs with existing contact services (likely already managing contacts there)
- ✅ Contacts available across all devices (phone, other email clients)
- ✅ Fast searching with local cache
- ✅ Offline support
- ✅ Can manually add/edit contacts via khard CLI
- ✅ Well-maintained and widely used
- ✅ Professional-grade tooling

**Cons**:
- ❌ Requires CardDAV service (but most email providers offer this)
- ❌ Manual contact curation - no auto-discovery from sent/received emails
- ❌ No frequency/recency ranking
- ❌ Requires periodic sync (not real-time, typically hourly)
- ❌ Medium setup complexity

**Maintenance**: Low after initial setup - automatic sync via systemd timer

---

### 2. Simple TSV File + grep

**Type**: Manual contact list
**Packages**: None (uses built-in grep or ripgrep)
**Autocomplete Quality**: ⭐⭐⭐ (Good for small lists)

#### How It Works

Create a plain text file with tab-separated email addresses and names:

```
alice@example.com	Alice Smith
bob@work.com	Bob Johnson
charlie@university.edu	Dr. Charlie Brown
```

Use grep/ripgrep to search it when autocompleting.

#### Setup Steps

1. Create `~/contacts.tsv` with your contacts
2. Add to aerc config: `address-book-cmd = rg -i -F "%s" ~/contacts.tsv`
   - Or with grep: `address-book-cmd = grep -i "%s" ~/contacts.tsv`

#### Pros and Cons

**Pros**:
- ✅ Works with any email backend (IMAP, maildir, etc.)
- ✅ Extremely simple - just a text file
- ✅ No dependencies beyond grep/ripgrep (already installed)
- ✅ Very fast searching
- ✅ Easy to backup and version control
- ✅ Human readable and editable
- ✅ Works immediately - no sync required
- ✅ Perfect for small contact lists (< 50 people)

**Cons**:
- ❌ Completely manual - must add every contact yourself
- ❌ No auto-discovery from emails
- ❌ No ranking by frequency/recency
- ❌ High maintenance burden for large contact lists
- ❌ Contacts not synced to other devices

**Maintenance**: High - manual entry for each contact

**Best For**: Users who regularly email < 50 people and want the simplest possible solution.

---

### 3. aercbook (Semi-Automated)

**Type**: Lightweight address book with email parsing
**Repository**: https://github.com/insomniacslk/aercbook
**Package**: Not in nixpkgs - must build from source (Zig 0.11.0)
**Autocomplete Quality**: ⭐⭐⭐½ (Good with effort)

#### How It Works

- Stores contacts in plain text: `alias : email@example.com Name`
- Provides fuzzy search for autocomplete
- Can pipe emails to automatically extract contacts

#### Setup Steps

1. Build from source with Zig
2. Create/configure address book file
3. Add to aerc: `address-book-cmd = aercbook /path/to/addressbook.txt "%s"`
4. To extract contacts from emails: `cat email.eml | aercbook --parse --add-all`

#### Pros and Cons

**Pros**:
- ✅ Works with IMAP (manually pipe selected emails)
- ✅ Fuzzy search with modified Levenshtein distance
- ✅ Can auto-extract contacts from piped emails
- ✅ Fast and lightweight
- ✅ Auto-creates file on first use

**Cons**:
- ❌ Semi-manual: must manually pipe emails to extract contacts
- ❌ No automatic monitoring of sent/received emails
- ❌ No frequency/recency ranking
- ❌ Requires Zig 0.11.0 to build from source (not in nixpkgs)
- ❌ Small project with limited activity

**Maintenance**: Medium - must manually pipe emails for contact extraction

---

### 4. addr-book-combine (Hybrid Approach)

**Type**: Tool to merge multiple address book sources
**Package**: Not in nixpkgs - build from source
**Autocomplete Quality**: Depends on combined sources

#### How It Works

Combines multiple address book commands into one unified search:
- Removes duplicates
- Sorts by priority (sources listed first = higher priority)
- Can merge khard (CardDAV) + TSV file + aercbook

Example:
```bash
address-book-cmd = addr-book-combine \
    -c "khard email --remove-first-line --parsable '%s'" \
    -c "rg -F -i -- '%s' ~/.contacts.tsv"
```

#### Pros and Cons

**Pros**:
- ✅ Best of both worlds - combine automated + manual contacts
- ✅ Prioritizes sources in order specified
- ✅ Removes duplicates intelligently
- ✅ Can combine khard (synced contacts) with manually maintained frequent correspondents

**Cons**:
- ❌ Adds complexity
- ❌ Requires at least one other address book solution
- ❌ Additional dependency to build

**Use Case**: Advanced users who want khard for main contacts + TSV for frequent one-off correspondents.

---

## Feature Comparison

| Feature | maildir-rank-addr | khard+vdirsyncer | Simple TSV | aercbook | addr-book-combine |
|---------|-------------------|------------------|------------|----------|-------------------|
| **IMAP-Only Compatible** | ❌ No (needs maildir) | ✅ Yes | ✅ Yes | ✅ Yes (manual) | ✅ Yes |
| **Auto-Discovery** | ✅ Automatic | ❌ Manual sync | ❌ Manual | ⚠️ Semi-auto | Depends on sources |
| **Frequency Ranking** | ✅ Yes | ❌ No | ❌ No | ❌ No | ⚠️ Partial |
| **Recency Ranking** | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |
| **Setup Complexity** | Medium | Medium | Very Low | Low-Medium | Medium |
| **Maintenance** | Very Low | Low | High | Medium | Low-Medium |
| **Search Speed** | Fast | Fast | Fast | Fast | Fast |
| **Offline Support** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Cross-Device Sync** | ❌ No | ✅ Yes (CardDAV) | ❌ No | ❌ No | ⚠️ Via khard |
| **Package in nixpkgs** | ✅ Yes | ✅ Yes | N/A | ❌ No | ❌ No |
| **Maturity** | Medium | High | N/A | Low | Medium |
| **NixOS Integration** | Easy | Easy | Trivial | Manual build | Manual build |

---

## NixOS Implementation Details

### Option 1: khard + vdirsyncer (Recommended for IMAP-only)

#### Package Installation

Add to `home-manager/server/email/default.nix`:

```nix
home.packages = with pkgs; [
  # ... existing packages ...
  khard         # CardDAV contact manager
  vdirsyncer    # CardDAV sync tool
];
```

#### vdirsyncer Configuration

Create `home-manager/server/email/vdirsyncer-config`:

```ini
[general]
status_path = "~/.local/share/vdirsyncer/status/"

# Google Contacts for brown account
[pair brown_contacts]
a = "brown_contacts_local"
b = "brown_contacts_remote"
collections = ["from a", "from b"]

[storage brown_contacts_local]
type = "filesystem"
path = "~/.contacts/brown"
fileext = ".vcf"

[storage brown_contacts_remote]
type = "carddav"
url = "https://www.googleapis.com/carddav/v1/principals/lachlan_kermode@brown.edu/lists/default/"
username = "lachlan_kermode@brown.edu"
password.fetch = ["command", "pass", "show", "email/brown"]

# Google Contacts for gmail account
[pair gmail_contacts]
a = "gmail_contacts_local"
b = "gmail_contacts_remote"
collections = ["from a", "from b"]

[storage gmail_contacts_local]
type = "filesystem"
path = "~/.contacts/gmail"
fileext = ".vcf"

[storage gmail_contacts_remote]
type = "carddav"
url = "https://www.googleapis.com/carddav/v1/principals/lachiekermode@gmail.com/lists/default/"
username = "lachiekermode@gmail.com"
password.fetch = ["command", "pass", "show", "email/gmail"]
```

Load it in NixOS:

```nix
xdg.configFile."vdirsyncer/config".source = ./vdirsyncer-config;
```

#### khard Configuration

Create `home-manager/server/email/khard-config`:

```ini
[general]
debug = no
default_action = list
editor = $EDITOR

[contact table]
display = first_name
group_by_addressbook = no
reverse = no
show_nicknames = yes
show_uids = no
sort = last_name
localize_dates = yes

[vcard]
preferred_version = 3.0
search_in_source_files = no
skip_unparsable = no

[[addressbooks]]
[addressbooks.brown]
path = ~/.contacts/brown/default/

[[addressbooks]]
[addressbooks.gmail]
path = ~/.contacts/gmail/default/
```

Load it in NixOS:

```nix
xdg.configFile."khard/khard.conf".source = ./khard-config;
```

#### Aerc Configuration

Add to `programs.aerc.extraConfig.general`:

```nix
programs.aerc.extraConfig = {
  general = {
    # ... existing config ...
    address-book-cmd = "khard email --remove-first-line --parsable '%s'";
  };
  # ... rest of config ...
};
```

#### Automatic Sync with Systemd

Add to home-manager configuration:

```nix
# Service to run vdirsyncer sync
systemd.user.services.vdirsyncer = {
  Unit = {
    Description = "Synchronize CardDAV contacts for aerc";
  };
  Service = {
    Type = "oneshot";
    ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
  };
};

# Timer to run sync hourly
systemd.user.timers.vdirsyncer = {
  Unit = {
    Description = "Synchronize CardDAV contacts hourly";
  };
  Timer = {
    OnCalendar = "hourly";
    Persistent = true;
  };
  Install = {
    WantedBy = [ "timers.target" ];
  };
};
```

#### Initial Setup Commands

After deploying:

```bash
# Discover collections
vdirsyncer discover

# Initial sync
vdirsyncer sync

# Verify contacts loaded
khard list

# Test search
khard email smith

# Enable and start timer
systemctl --user enable vdirsyncer.timer
systemctl --user start vdirsyncer.timer
```

---

### Option 2: Simple TSV File

#### Create Contacts File

Create `home-manager/server/email/contacts.tsv`:

```
alice@example.com	Alice Smith
bob@work.com	Bob Johnson
charlie@university.edu	Dr. Charlie Brown
```

#### Load in NixOS

Add to `home-manager/server/email/default.nix`:

```nix
# Copy contacts file to home directory
home.file.".contacts.tsv".source = ./contacts.tsv;
```

#### Aerc Configuration

```nix
programs.aerc.extraConfig = {
  general = {
    # ... existing config ...
    address-book-cmd = "rg -i -F '%s' ~/.contacts.tsv";
  };
  # ... rest of config ...
};
```

That's it! No additional packages needed (ripgrep is already in your config).

---

### Option 3: maildir-rank-addr (If switching to maildir)

This is the full implementation if you decide to switch from IMAP to maildir.

#### Package Installation

```nix
home.packages = with pkgs; [
  # ... existing packages ...
  maildir-rank-addr  # Address book generator
  isync              # mbsync for maildir sync
  ugrep              # Fast search (or use ripgrep)
];
```

#### Enable mbsync for Email Accounts

For each account in `accounts.email.accounts`:

```nix
accounts.email.accounts = {
  "brown" = {
    # ... existing config ...
    mbsync = {
      enable = true;
      create = "both";  # Create missing folders on both sides
      expunge = "both"; # Delete emails on both sides
      patterns = [ "*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Starred" ];
    };
  };
  # Repeat for gmail, inferstudio, etc.
};

# Enable mbsync program
programs.mbsync.enable = true;
```

#### Change Aerc from IMAP to Maildir

Modify aerc account configs:

```nix
accounts.email.accounts = {
  "brown" = {
    # ... other config stays the same ...

    # REMOVE: aerc.extraAccounts.source (IMAP)
    # REMOVE: aerc.extraAccounts.outgoing

    # Aerc will automatically use maildir from mbsync
    aerc = {
      enable = true;
      extraAccounts = {
        cache-headers = "true";
        folder-map = "~/.config/aerc/brown-foldermap";
        # source/outgoing determined automatically from mbsync
      };
    };
  };
};
```

#### Configure maildir-rank-addr

Create `home-manager/server/email/maildir-rank-addr-config`:

```toml
maildir = "/home/lox/Mail"
addresses = [
    "lachlan_kermode@brown.edu",
    "lachiekermode@gmail.com",
    "lachlan@inferstudio.com"
]
outputpath = "~/.cache/maildir-rank-addr/addressbook.tsv"
template = "{{.Address}}\t{{.Name}}\t{{.NormalizedName}}"
filters = ["noreply@", "no-reply@", "donotreply@"]
```

Load it:

```nix
xdg.configFile."maildir-rank-addr/config".text = builtins.readFile ./maildir-rank-addr-config;
```

#### Aerc Configuration

```nix
programs.aerc.extraConfig = {
  general = {
    # ... existing config ...
    address-book-cmd = "ugrep -jP -m 100 --color=never '%s' ~/.cache/maildir-rank-addr/addressbook.tsv";
  };
  # ... rest of config ...
};
```

#### Automatic Updates with Systemd

```nix
# Service to update address rankings
systemd.user.services.maildir-rank-addr = {
  Unit = {
    Description = "Update email address rankings for aerc";
  };
  Service = {
    Type = "oneshot";
    ExecStart = "${pkgs.maildir-rank-addr}/bin/maildir-rank-addr";
  };
};

# Timer to run daily
systemd.user.timers.maildir-rank-addr = {
  Unit = {
    Description = "Update email address rankings daily";
  };
  Timer = {
    OnCalendar = "daily";
    Persistent = true;
  };
  Install = {
    WantedBy = [ "timers.target" ];
  };
};
```

#### Initial Setup Commands

After deploying:

```bash
# Initial mbsync to download all emails
mbsync -a  # This may take a while for large mailboxes

# Generate initial address database
maildir-rank-addr

# Verify output
ls -lh ~/.cache/maildir-rank-addr/addressbook.tsv
head ~/.cache/maildir-rank-addr/addressbook.tsv

# Test search
ugrep -jP -m 100 --color=never "smith" ~/.cache/maildir-rank-addr/addressbook.tsv

# Enable timer
systemctl --user enable maildir-rank-addr.timer
systemctl --user start maildir-rank-addr.timer
```

---

## Recommendations

### For IMAP-Only Setup (Current)

**Recommended: khard + vdirsyncer**

Choose this if:
- You want to keep using IMAP directly (no local mail storage)
- You already use Google Contacts or another CardDAV service
- You want contacts synced across devices
- You're willing to do one-time medium-complexity setup
- You prefer curated contact lists over automatic discovery

**Alternative: Simple TSV file**

Choose this if:
- You email < 50 people regularly
- You want the absolute simplest solution
- You're okay with manual contact management
- You want something working immediately

### For Maildir Setup (Switching from IMAP)

**Recommended: maildir-rank-addr**

Choose this if:
- You want automatic contact discovery and ranking
- You're willing to download emails locally (disk space)
- You want zero-maintenance autocomplete
- You prefer comprehensive contact lists over curated ones
- You value offline email access

### Decision Matrix

Ask yourself:

1. **Do I want to keep IMAP-only?**
   - Yes → khard + vdirsyncer OR simple TSV
   - No, willing to switch to maildir → maildir-rank-addr

2. **Do I already maintain contacts elsewhere?** (Google Contacts, etc.)
   - Yes → khard + vdirsyncer (sync what you already have)
   - No → simple TSV OR maildir-rank-addr

3. **How many people do I regularly email?**
   - < 50 → Simple TSV is fine
   - 50-500 → khard or maildir-rank-addr
   - 500+ → maildir-rank-addr (automatic ranking essential)

4. **Do I value curated vs comprehensive contact lists?**
   - Curated (quality) → khard or simple TSV
   - Comprehensive (quantity) → maildir-rank-addr

### What Most Aerc Users Choose

Based on community research:
1. **IMAP users**: Most use khard + vdirsyncer
2. **Maildir users**: Most use maildir-rank-addr
3. **Minimalists**: Simple TSV file is popular for small contact lists

---

## Conclusion

All approaches provide functional autocomplete. The choice depends on:
- Whether you want to switch to maildir (enables maildir-rank-addr)
- How much manual maintenance you're willing to do
- Whether you want cross-device contact sync
- Your contact list size

The good news: You can start simple (TSV file) and upgrade later (khard or maildir-rank-addr) without losing any email functionality. The autocomplete is just a configuration change away.
