{pkgs, inputs, system, naersk, ...}:
let
  naersk' = pkgs.callPackage naersk {};
in
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
    ripgrep     # `rg` is a better grep
    fd          # `fd` is a better find
    jq          # A lightweight and flexible command-line JSON processor
    vivid       # for colorschemes
    just        # better makefiles
    lazygit     # git tui client
    lazydocker  # docker tui client
    pandoc      # document processor
    tectonic    # LaTeX compilation
    bartib      # time tracking
    git-crypt   # encrypted git repos
    imagemagick # manipulate images from the command-line
    ffmpeg-full # utility for sound, image, video

    inputs.typst.packages.${system}.default  # for better typesetting (from upstream main)
    delta       # syntax-highlighting in git and jj diffs

    # Terminal-based diff viewer with interactive file tree navigation
    (naersk'.buildPackage rec {
      pname = "ftdv";
      version = "0.1.2";

      src = pkgs.fetchFromGitHub {
        owner = "wtnqk";
        repo = pname;
        rev = "v${version}";
        sha256 = "sha256-J1lWrfZeH/V1hckLGWDoeU6aKFoLimddzaTKMQ8sDs8=";
      };
    })

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
    gt = "lazygit";
    dt = "lazydocker";
    t = "tmux";
    b = "bartib -f ~/.bartib";
    c = "clear";
    pdfpc = "pdfpc -Z 1000:1000"; # necessary due to using tiling window manager
    python = "nvim-python3"; # so we don't have multiple Python installations for scripts
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.bash}/bin/bash -c 'vivid generate molokai')";

    # Claude code
    DISABLE_TELEMETRY = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;

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

    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Lachlan Kermode";
          email = "lachie@ohrg.org";
        };
        ui.default-command = "log";
        ui.pager = "delta";
        ui.diff-formatter = ":git";
      };
    };

    git = {
      enable = true;
      userName = "Lachlan Kermode";
      userEmail = "lachiekermode@gmail.com";

      lfs.enable = true;
      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        core.editor = "$EDITOR";

        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        delta.navigate = true;
        delta.dark = true;
        merge.conflictStyle = "zdiff3";
      };
    };
    
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

  # ftdv configuration
  xdg.configFile."ftdv/config.yaml".text = ''
    git:
      paging:
        pager: "delta --dark --paging=never --line-numbers --side-by-side -w={{diffAreaWidth}}"
        colorArg: "always"
    theme:
      name: dark
      colors:
        tree_line: dark_gray
        tree_selected_bg: '#323246'
        tree_selected_fg: yellow
        tree_directory: blue
        tree_file: white
        status_added: green
        status_removed: red
        status_modified: yellow
        border: dark_gray
        border_focused: cyan
        title: cyan
        status_bar_bg: dark_gray
        status_bar_fg: white
        text_primary: white
        text_secondary: gray
        text_dim: dark_gray
        background: black
  '';
}
