{pkgs, ...}: {
	services = {
		keybase.enable = true;
		kbfs.enable = true;
	};

	home.packages = with pkgs; [
		# profiling
		nix-tree
		# neofetch

		# archives
		zip
		xz

		# networking tools
		# mtr	# A network diagnostic tool
		# dnsutils # `dig` + `nslookup`
		# ldns	# replacement of `dig`, it provide the command `drill`
		# nmap			# A utility for network discovery and security auditing

		# Docs: https://github.com/learnbyexample/Command-line-text-processing
		gawk			# GNU awk, a pattern scanning and processing language
		ripgrep		# recursively searches directories for a regex pattern
		sad				# CLI search and replace, with diff preview 
		# delta			# A viewer for git and diff output
		ripgrep		# `rg` is a better grep
		fd				# `fd` is a better find
		jq				# A lightweight and flexible command-line JSON processor

		file
		which
		tree
		gnupg

		# fonts
		fira-code
		fira-code-symbols
		# font-awesome
		# noto-fonts
		
		vivid			# for colorschemes

		just			# better makefiles
		lazygit		# git tui client
		pandoc		# document processor
		tectonic	# LaTeX compilation
		pdftk			# pdf manipulation
		bartib		# time tracking
		git-crypt	# encrypted git repos

		# CSV management in terminal
		csvkit
		visidata 
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
		LS_COLORS = "${pkgs.bash}/bin/bash -c 'vivid generate catppuccin-macchiato'";
	};

	programs = {
		# email in the terminal
		aerc.enable = true;

		# cd but better
		zoxide.enable = true;

    # auto dev environments with nix flakes
    direnv = {
      enable = true;
      # enableFishIntegration = true; 
      nix-direnv.enable = true;
    };

		eza = {
			enable = true;
			git = true;
			icons = true;
		};

		# cat but better
		bat = {
			enable = true;
			config = {
				theme = "gruvbox-dark";
				pager = "less -FR";
			};
		};

		# file directory navigation
		broot = {
			enable = true;
			enableFishIntegration = true;
			settings = {
				modal = true;
			};
		};

		lf = {
			enable = true;
		};

		git = {
			enable = true;
			userName = "Lachlan Kermode";
			userEmail = "lachlankermode@live.com";

			lfs.enable = true;
			extraConfig = {
				init.defaultBranch = "main";
				push.autoSetupRemote = true;
				pull.rebase = true;
				core.editor = "$EDITOR";
			};

			# A syntax-highlighting pager in Rust
			# delta = {
			# 	enable = true;
			# 	options = {
			# 		diff-so-fancy = true;
			# 		line-numbers = true;
			# 		true-color = "always";
			# 	};
			# };
		};
		
		# jujutsu = {
		# 	enable = true;
		# 	settings = {
		# 		user = {
		# 			name = "Lachlan Kermode";
		# 			email = "hi@ohrg.org";
		# 		};
		# 	};
		# };

		# A command-line fuzzy finder
		fzf = {
			enable = true;
			colors = {
				# "bg+" = "#313244";
				# "bg" = "#1e1e2e";
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

		command-not-found.enable = false;

		btop = {
			enable = true;
			settings = {
				vim_keys = true;
			};
		};

	};
}
