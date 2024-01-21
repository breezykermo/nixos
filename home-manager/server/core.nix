{pkgs, ...}: {
	home.packages = with pkgs; [
		neofetch
		lazygit		# git tui client
		pandoc		# document processor
		tectonic	# LaTeX compilation
		bottom		# htop but better

		# archives
		zip
		xz

		# networking tools
		mtr				# A network diagnostic tool
		dnsutils	# `dig` + `nslookup`
		ldns			# replacement of `dig`, it provide the command `drill`
		nmap			# A utility for network discovery and security auditing

		# Text Processing
		# Docs: https://github.com/learnbyexample/Command-line-text-processing
		gnugrep		# GNU grep, provides `grep`/`egrep`/`fgrep`
		gnused		# GNU sed, mainly for replacing text in files
		gawk			# GNU awk, a pattern scanning and processing language
		ripgrep		# recursively searches directories for a regex pattern
		sad				# CLI search and replace, with diff preview 
		delta			# A viewer for git and diff output

		
		ast-grep	# for code searching, linting, rewriting at large scale
		jq				# A lightweight and flexible command-line JSON processor
		yq-go			# yaml processer https://github.com/mikefarah/yq

		file
		which
		tree
		gnupg
		git-trim # trims branches when tracking remote refs are merged or gone

		# nix related
		nix-output-monitor # `nom` works just like `nix with more details
		nodePackages.node2nix
	];

	home.shellAliases = {
		diff = "diff --color=auto";
		grep = "grep --color=auto";
		ip = "ip -color=auto";
		l = "exa --long --all --group --git --group-directories-first";
		e = "$EDITOR";
		g = "lazygit";
		t = "tmux";
	};

	programs = {
		alacritty = {
			enable = true;
			settings = {
				env.TERM = "xterm-256color";
				font = {
					size = 14;
					draw_bold_text_with_bright_colors = true;
				};
				scrolling.multiplier = 5;
				selection.save_to_clipboard = true;
			};
		};

		# cd but better
		zoxide.enable = true;

		# ls but better
		exa = {
			enable = true;
			enableAliases = true;
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
				"bg+" = "#313244";
				"bg" = "#1e1e2e";
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

		# Basically anywhere you would want to use grep, try sk instead.
		skim = {
			enable = true;
			enableBashIntegration = true;
		};

		dircolors = {
			enable = true;
		};

		command-not-found.enable = false;
	};

	services = {
		keybase = {
			enable = true;
		};
		kbfs = {
			enable = true;
		};
	};
}
