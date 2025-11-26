{pkgs, inputs, system, lib, ...}:
let
  theme = import ../../themes/default.nix { inherit lib; };
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
    lazydocker  # docker tui client
    bartib      # time tracking
    imagemagick # manipulate images from the command-line
    ffmpeg-full # utility for sound, image, video
    gh          # Github CLI
    uv          # Python package installer and resolver

    # Rheo (from flake input)
    inputs.rheo.packages.${system}.default
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
    python = "nvim-python3"; 
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.bash}/bin/bash -c 'vivid generate ${theme.fullName}')";

    # PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
    # pnpm config set global-bin-dir ~/.local/bin
    # pnpm config set store-dir ~/.local/share/pnpm/store
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
  };
}
