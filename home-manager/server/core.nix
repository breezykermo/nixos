{pkgs, ...}: {
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
    gawk			  # GNU awk, a pattern scanning and processing language
    ripgrep		  # recursively searches directories for a regex pattern
    sad				  # CLI search and replace, with diff preview 
		ripgrep		  # `rg` is a better grep
		fd				  # `fd` is a better find
		jq				  # A lightweight and flexible command-line JSON processor
    vivid			  # for colorschemes
		just			  # better makefiles
		lazygit		  # git tui client
    lazydocker  # docker tui client
		pandoc		  # document processor
		tectonic	  # LaTeX compilation
		pdftk			  # pdf manipulation
		bartib		  # time tracking
		git-crypt	  # encrypted git repos
    imagemagick # manipulate images from the command-line
    ffmpeg-full # utility for sound, image, video

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
		g = "lazygit";
		t = "tmux";
		z = "zoxide";
		b = "bartib -f ~/.bartib";
    c = "clear";
	};

	home.sessionVariables = {
		LS_COLORS = "$(${pkgs.bash}/bin/bash -c 'vivid generate gruvbox-dark')";
	};

	programs = {
		# email in the terminal
    # NOTE: app passwords are per device, generate new ones if using this config
    # TODO: [compose] format-flowed=true
    # as currently this is just in my local config.
		aerc.enable = true;

		# cd but better
		zoxide.enable = true;

    # auto dev environments with nix flakes
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      # enableFishIntegration = true; 
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
			};

			# A syntax-highlighting pager in Rust
			delta = {
				enable = true;
				options = {
					diff-so-fancy = true;
					line-numbers = true;
					true-color = "always";
				};
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
}
