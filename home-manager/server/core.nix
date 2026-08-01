{
  pkgs,
  inputs,
  system,
  lib,
  theme,
  ...
}: {
  services = {
    keybase.enable = true;
    kbfs.enable = true;
    ssh-agent.enable = true;
  };

  home.packages = with pkgs; [
    nix-tree # profiling
    nix-index # local index of nixpkgs for search
    unzip # archives
    zip
    xz
    lz4
    file # general file utils
    which
    tree
    gawk # GNU awk, a pattern scanning and processing language
    ripgrep # recursively searches directories for a regex pattern
    sad # CLI search and replace, with diff preview
    fd # `fd` is a better find
    jq # A lightweight and flexible command-line JSON processor
    vivid # for colorschemes
    just # better makefiles
    bartib # time tracking
    imagemagick # manipulate images from the command-line
    ffmpeg-full # utility for sound, image, video
    gh # Github CLI
    uv # Python package installer and resolver
    python3 # Python interpreter
    sqlite # useful little database
    cargo-binstall # install pre-built Rust binaries
    flyctl # fly.io CLI
    kagimcp # Kagi MCP server for web search
    lnav # log file navigator (generic formats, journald, SQL queries)
    mosh # mobile shell - resilient to roaming and intermittent connectivity
  ];

  # gh extension: dlvhdr/gh-dash, invoked as `gh dash`
  home.file.".local/share/gh/extensions/gh-dash/gh-dash".source = "${pkgs.gh-dash}/bin/gh-dash";

  home.shellAliases = {
    diff = "diff --color=auto";
    grep = "grep --color=auto";
    ip = "ip -color=auto";
    l = "exa --long --all --group --group-directories-first";
    a = "abacus";
    t = "tmux";
    b = "bartib -f ~/.bartib";
    c = "clear";
    m = "maestral";
    # Bluetooth radio on/off on demand (framework leaves it off at boot — see
    # custom.bluetooth.powerOnBoot). No sudo needed: bluetoothctl uses the bluez
    # D-Bus interface as a regular user.
    bt-on = "bluetoothctl power on";
    bt-off = "bluetoothctl power off";
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.bash}/bin/bash -c 'vivid generate ${theme.vividTheme}')";
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
        # bat's themes are .tmTheme files with baked-in hex colors, so none of
        # them can track themes/default.nix. "ansi" draws only from the terminal's
        # 16 colors, which ghostty sets from the active palette (see the
        # `palette =` block in home-manager/desktop/default.nix) -- so bat, delta
        # (which uses bat's themes) and LS_COLORS all stay in sync by
        # construction. Swap for a named theme (`bat --list-themes`) to override.
        theme = "ansi";
        pager = "less -FR";
      };
    };

    # file directory navigation
    lf = {
      enable = true;
      keybindings = {
        "s" = "${pkgs.fish}/bin/fish";
      };
    };

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
      # The ROCm-enabled btop package (for GPU monitoring) is homework-only; see
      # home-manager/server/homework.nix.
      settings = {
        vim_keys = true;
        color_theme = "system";
        # Let the terminal background show through (ghostty runs at
        # theme.transparency.opacity), matching tuicr/neovim.
        theme_background = false;
        truecolor = true;
      };
      # Palette-driven theme, written to ~/.config/btop/themes/system.theme.
      # btop themes are flat `theme[key]="#rrggbb"` files; the *_start/_mid/_end
      # triples are gradient stops for the meters and graphs.
      themes.system = ''
        theme[main_bg]="${theme.background}"
        theme[main_fg]="${theme.foreground}"
        theme[title]="${theme.foreground}"
        theme[hi_fg]="${theme.colors.blue}"
        theme[selected_bg]="${theme.colors.bg2}"
        theme[selected_fg]="${theme.foreground}"
        theme[inactive_fg]="${theme.colors.fg4}"
        theme[graph_text]="${theme.colors.fg2}"
        theme[meter_bg]="${theme.colors.bg2}"
        theme[proc_misc]="${theme.colors.purple}"

        theme[cpu_box]="${theme.colors.blue}"
        theme[mem_box]="${theme.colors.green}"
        theme[net_box]="${theme.colors.purple}"
        theme[proc_box]="${theme.colors.aqua}"
        theme[div_line]="${theme.colors.bg3}"

        theme[temp_start]="${theme.colors.blue}"
        theme[temp_mid]="${theme.colors.yellow}"
        theme[temp_end]="${theme.colors.red}"

        theme[cpu_start]="${theme.colors.aqua}"
        theme[cpu_mid]="${theme.colors.blue}"
        theme[cpu_end]="${theme.colors.purple}"

        theme[free_start]="${theme.colors.bg3}"
        theme[free_mid]="${theme.colors.gray}"
        theme[free_end]="${theme.colors.fg2}"

        theme[cached_start]="${theme.colors.aqua}"
        theme[cached_mid]="${theme.colors.blue}"
        theme[cached_end]="${theme.colors.bright_blue}"

        theme[available_start]="${theme.colors.yellow}"
        theme[available_mid]="${theme.colors.orange}"
        theme[available_end]="${theme.colors.bright_orange}"

        theme[used_start]="${theme.colors.green}"
        theme[used_mid]="${theme.colors.bright_green}"
        theme[used_end]="${theme.colors.red}"

        theme[download_start]="${theme.colors.aqua}"
        theme[download_mid]="${theme.colors.blue}"
        theme[download_end]="${theme.colors.bright_blue}"

        theme[upload_start]="${theme.colors.purple}"
        theme[upload_mid]="${theme.colors.bright_purple}"
        theme[upload_end]="${theme.colors.bright_red}"

        theme[process_start]="${theme.colors.green}"
        theme[process_mid]="${theme.colors.yellow}"
        theme[process_end]="${theme.colors.red}"
      '';
    };
  };
}
