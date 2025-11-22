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

    # Wrap typst with required libraries (OpenSSL 3)
    (pkgs.symlinkJoin {
      name = "typst-wrapped";
      paths = [ inputs.typst.packages.${system}.default ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/typst \
          --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.openssl ]}"
      '';
    })

    gh          # Github CLI
    uv          # Python package installer and resolver

    # TR-100 Machine Report - system info display utility
    (pkgs.stdenv.mkDerivation {
      name = "usgc-machine-report";
      version = "1.0.0";

      src = pkgs.fetchFromGitHub {
        owner = "usgraphics";
        repo = "usgc-machine-report";
        rev = "master";
        sha256 = "sha256-0XX7FIAMdp5rEbvsu4+09a19g0kkM4v6Y5ynudpbQlI=";
      };

      buildInputs = [ pkgs.util-linux ];

      installPhase = ''
        mkdir -p $out/bin
        cp machine_report.sh $out/bin/machine-report
        chmod +x $out/bin/machine-report
      '';

      meta = with pkgs.lib; {
        description = "TR-100 Machine Report - system information display utility";
        homepage = "https://github.com/usgraphics/usgc-machine-report";
        license = licenses.bsd3;
      };
    })

    # NOTE: in general, I don't want this. but due to tectonic sometimes not
    # being able to do what I need, it is nice to have.
    # texlive.combined.scheme-medium

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
    pdfpc = "pdfpc -Z 1000:1000"; # necessary due to using tiling window manager
    python = "nvim-python3"; 
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.bash}/bin/bash -c 'vivid generate gruvbox-dark')";

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
