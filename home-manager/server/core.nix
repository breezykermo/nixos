{pkgs, inputs, system, lib, theme, machineVars, localProfile, ...}:
{
  services = {
    keybase.enable = true;
    kbfs.enable = true;
    ssh-agent.enable = true;
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
    python3     # Python interpreter
    sqlite      # useful little database
    cargo-binstall # install pre-built Rust binaries
    flyctl        # fly.io CLI
    kagimcp       # Kagi MCP server for web search
    lnav          # log file navigator (generic formats, journald, SQL queries)
    mosh          # mobile shell - resilient to roaming and intermittent connectivity
  ];

  # gh extension: dlvhdr/gh-dash, invoked as `gh dash`
  home.file.".local/share/gh/extensions/gh-dash/gh-dash".source = "${pkgs.gh-dash}/bin/gh-dash";

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
    # Bluetooth radio on/off on demand (framework leaves it off at boot — see
    # custom.bluetooth.powerOnBoot). No sudo needed: bluetoothctl uses the bluez
    # D-Bus interface as a regular user.
    bt-on = "bluetoothctl power on";
    bt-off = "bluetoothctl power off";
  } // lib.optionalAttrs (localProfile == "homework") {
    # reMarkable tablet: run with landscape rotation (USB-C on left)
    # Use -r 1 for 90° CW, -r 2 for 180°, -r 3 for 270° CW
    rmt = "rmTabletDriver --key=/home/${machineVars.userName}/.ssh/${machineVars.remarkableKey} -r 2";
    rmt-portrait = "rmTabletDriver --key=/home/${machineVars.userName}/.ssh/${machineVars.remarkableKey}";
    # Monitor switching (note: may not work due to Hyprland tablet limitations)
    rm-laptop = "hyprctl keyword device:remarkabletablet-fakepen:output eDP-1";
    rm-external = "hyprctl keyword device:remarkabletablet-fakepen:output DP-1";
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
        theme = "Catppuccin Mocha";
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
      };
    };

  };
}
