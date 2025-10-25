{pkgs, inputs, system, ...}: {
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
    ripgrep     # `rg` is a better grep
    fd          # `fd` is a better find
    jq          # A lightweight and flexible command-line JSON processor
    vivid       # for colorschemes
    just        # better makefiles
    lazydocker  # docker tui client
    pandoc      # document processor
    tectonic    # LaTeX compilation
    bartib      # time tracking
    imagemagick # manipulate images from the command-line
    ffmpeg-full # utility for sound, image, video

    inputs.typst.packages.${system}.default  # for better typesetting (from upstream main)

    gh          # Github CLI

    # NOTE: in general, I don't want this. but due to tectonic sometimes not
    # being able to do what I need, it is nice to have.
    # texlive.combined.scheme-medium 

  ];

  home.shellAliases = {
    diff = "diff --color=auto";
    grep = "grep --color=auto";
    ip = "ip -color=auto";
    l = "exa --long --all --group --git --group-directories-first";
    e = "$EDITOR";
    dt = "lazydocker";
    t = "tmux";
    b = "bartib -f ~/.bartib";
    c = "clear";
    pdfpc = "pdfpc -Z 1000:1000"; # necessary due to using tiling window manager
    python = "nvim-python3"; 
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.bash}/bin/bash -c 'vivid generate molokai')";

    # PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
    # pnpm config set global-bin-dir ~/.local/bin
    # pnpm config set store-dir ~/.local/share/pnpm/store
  };

  programs = {
    # email in the terminal
    # NOTE: app passwords are per device, generate new ones if using this config
    # TODO: [compose] format-flowed=true
    # as currently this is just in my local config.
    aerc = {
      enable = true;
      extraConfig = { ui = { sort = "-r date"; }; };
    };

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
        theme = "gruvbox-dark";
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
        "spinner" = "#f5e0dc";
        "hl" = "#f38ba8";
        "fg" = "#cdd6f4";
        "header" = "#f38ba8";
        "info" = "#cba6f7";
        "pointer" = "#f5e0dc";
        "marker" = "#f5e0dc";
        "fg+" = "#cdd6f4";
        "prompt" = "#cba6f7";
        "hl+" = "#f38ba8";
      };
    };

    # top but better
    btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };
  };
}
