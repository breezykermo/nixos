{pkgs, inputs, system, lib, theme, ...}:
{
  services = {
    keybase.enable = true;
    kbfs.enable = true;
  };

  home.packages = with pkgs; [
    nix-tree    # profiling
    nix-index   # local index of nixpkgs for search
    unzip       # archives
    zip
    xz
    lz4
    file        # general file utils
    which
    tree
    gawk        # GNU awk, a pattern scanning and processing language
    ripgrep     # recursively searches directories for a regex pattern
    sad         # CLI search and replace, with diff preview
    fd          # `fd` is a better find
    jq          # A lightweight and flexible command-line JSON processor
    vivid       # for colorschemes
    just        # better makefiles
    lazydocker  # docker tui client
    bartib      # time tracking
    imagemagick # manipulate images from the command-line
    ffmpeg-full # utility for sound, image, video
    gh          # Github CLI
    uv          # Python package installer and resolver
    sqlite      # useful little database
    cargo-binstall # install pre-built Rust binaries

  ];

  home.shellAliases = {
    diff = "diff --color=auto";
    grep = "grep --color=auto";
    ip = "ip -color=auto";
    l = "exa --long --all --group --group-directories-first";
    e = "$EDITOR";
    t = "tmux";
    b = "bartib -f ~/.bartib";
    c = "clear";
    m = "maestral";
    # reMarkable tablet: run with landscape rotation (USB-C on left)
    # Use -r 1 for 90° CW, -r 2 for 180°, -r 3 for 270° CW
    rmt = "rmTabletDriver --key=/home/lox/.ssh/id_rsa_remarkable -r 3";
    rmt-portrait = "rmTabletDriver --key=/home/lox/.ssh/id_rsa_remarkable";
    # Monitor switching (note: may not work due to Hyprland tablet limitations)
    rm-laptop = "hyprctl keyword device:remarkabletablet-fakepen:output eDP-1";
    rm-external = "hyprctl keyword device:remarkabletablet-fakepen:output DP-1";
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.bash}/bin/bash -c 'vivid generate ${theme.fullName}')";
  };

  programs = {
    # cd but better
    zoxide.enable = true;

    # auto dev environments with nix flakes
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # ls but better
    eza = {
      enable = true;
      git = true;
      icons = "auto";
    };

    # cat but better
    bat = {
      enable = true;
      config = {
        theme = "${theme.fullName}";
        pager = "less -FR";
      };
    };

    # file directory navigation, option 1
    broot = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        modal = true;
      };
    };

    # file directory navigation, option 2
    lf.enable = true;

    # A command-line fuzzy finder
    fzf = {
      enable = true;
      colors = {
        "spinner" = theme.colors.fg1;
        "hl" = theme.colors.red;
        "fg" = theme.foreground;
        "header" = theme.colors.red;
        "info" = theme.colors.purple;
        "pointer" = theme.colors.fg1;
        "marker" = theme.colors.fg1;
        "fg+" = theme.foreground;
        "prompt" = theme.colors.purple;
        "hl+" = theme.colors.red;
      };
    };

    # top but better
    btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };

    # RSS/Atom feed reader
    newsboat = {
      enable = true;
      urls = [
        {
          url = "https://academicjobs.fandom.com/api.php?hidebots=1&urlversion=1&days=7&limit=50&action=feedrecentchanges&feedformat=rss";
          tags = [ "jobs" "~I-School Feed" ];
        }
        {
          url = "https://academicjobs.fandom.com/wiki/I-School_2025-2026?feed=rss&action=history";
          tags = [ "jobs" ];
        }
        {
          url = "https://joblist.mla.org/jobsrss/?Positiontype=20752179&Organizationtype=20752199&Languages=20752056&countrycode=US";
          tags = [ "jobs" "~MLA TT" ];
        }
        {
          url = "https://www.timeshighereducation.com/unijobs/jobsrss/?AcademicDiscipline=513013%2c5%2c20&JobType=32%2c36%2c38%2c39&countrycode=GB";
          tags = [ "jobs" "~THA Britain" ];
        }
        {
          url = "https://www.jobs.ac.uk/jobs/academic-or-research/?format=rss";
          tags = [ "jobs" "~jobs.ac.uk" ];
        }
        {
          url = "https://oxide.computer/careers/feed";
          tags = [ "jobs" "~Oxide" ];
        }

      ];
      extraConfig = ''
        # Vim-style keybindings
        bind-key j down
        bind-key k up
        bind-key J next-feed
        bind-key K prev-feed
        bind-key G end
        bind-key g home
        bind-key d pagedown
        bind-key u pageup
        bind-key l open
        bind-key h quit
        bind-key a toggle-article-read
        bind-key n next-unread
        bind-key N prev-unread
        bind-key D pb-download
        bind-key U show-urls
        bind-key x pb-delete

        # General settings
        auto-reload yes
        reload-time 120
        reload-threads 4
        download-retries 4
        download-timeout 30
        prepopulate-query-feeds yes

        # HTML rendering with w3m (same as aerc)
        html-renderer "${pkgs.w3m}/bin/w3m -dump -T text/html -cols 100 -o display_link_number=1"

        # Gruvbox theme colors
        color background         default   default
        color listnormal         ${theme.helpers.to256Color theme.colors.fg1}  default
        color listnormal_unread  ${theme.helpers.to256Color theme.colors.yellow}  default  bold
        color listfocus          ${theme.helpers.to256Color theme.colors.fg0}  ${theme.helpers.to256Color theme.colors.bg2}  bold
        color listfocus_unread   ${theme.helpers.to256Color theme.colors.orange}  ${theme.helpers.to256Color theme.colors.bg2}  bold
        color info               ${theme.helpers.to256Color theme.colors.aqua}  ${theme.helpers.to256Color theme.colors.bg1}  bold
        color article            ${theme.helpers.to256Color theme.colors.fg1}  default

        # Highlights for article content
        highlight article "^(Feed|Title|Author|Link|Date|Podcast Download URL):.*$" ${theme.helpers.to256Color theme.colors.aqua} default bold
        highlight article "https?://[^ ]+" ${theme.helpers.to256Color theme.colors.blue} default underline
        highlight article "\\[[0-9]+\\]" ${theme.helpers.to256Color theme.colors.orange} default bold
        highlight article "\\[image\\ [0-9]+\\]" ${theme.helpers.to256Color theme.colors.purple} default bold

        # Quote highlighting (similar to aerc colorize)
        highlight article "^>.*$" ${theme.helpers.to256Color theme.colors.green} default
        highlight article "^>>.*$" ${theme.helpers.to256Color theme.colors.aqua} default
        highlight article "^>>>.*$" ${theme.helpers.to256Color theme.colors.blue} default
      '';
    };
  };
}
