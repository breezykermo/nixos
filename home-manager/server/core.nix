{pkgs, ...}: {
	home.packages = with pkgs; [
		neofetch
		ranger # terminal file manager(batteries included, with image preview support)
		lazygit # git tui client
		pandoc # document processor
		tectonic # LaTeX compilation
		bottom # htop but better

		# archives
		zip
		xz

		# networking tools
		mtr # A network diagnostic tool
		dnsutils # `dig` + `nslookup`
		ldns # replacement of `dig`, it provide the command `drill`
		nmap # A utility for network discovery and security auditing

		# Text Processing
		# Docs: https://github.com/learnbyexample/Command-line-text-processing
		gnugrep  # GNU grep, provides `grep`/`egrep`/`fgrep`
		gnused  # GNU sed, very powerful(mainly for replacing text in files)
		gawk   # GNU awk, a pattern scanning and processing language
		ripgrep # recursively searches directories for a regex pattern
		sad  # CLI search and replace, with diff preview, really useful!!!
		delta  # A viewer for git and diff output

		# A fast and polyglot tool for code searching, linting, rewriting at large scale
		# supported languages: only some mainstream languages currently(do not support nix/nginx/yaml/toml/...)
		ast-grep
		jq # A lightweight and flexible command-line JSON processor
		yq-go # yaml processer https://github.com/mikefarah/yq

		file
		which
		tree
		gnupg

		# nix related
		#
		# it provides the command `nom` works just like `nix
		# with more details log output
		nix-output-monitor
		nodePackages.node2nix

		# Automatically trims your branches whose tracking remote refs are merged or gone
		# It's really useful when you work on a project for a long time.
		git-trim
	];

	home.shellAliases = {
		# Enable colors
		diff = "diff --color=auto";
		grep = "grep --color=auto";
		ip = "ip -color=auto";

		# Shortcuts
		l = "exa --long --all --group --git --group-directories-first";
		e = "$EDITOR";
		g = "lazygit";
	};

	programs = {
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

				# replace https with ssh
				# url = {
				#   "ssh://git@github.com/" = {
				#     insteadOf = "https://github.com/";
				#   };
				#   "ssh://git@gitlab.com/" = {
				#     insteadOf = "https://gitlab.com/";
				#   };
				#   "ssh://git@bitbucket.com/" = {
				#     insteadOf = "https://bitbucket.com/";
				#   };
				# };
			};

			# A syntax-highlighting pager in Rust(2019 ~ Now)
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

		# skim provides a single executable: sk.
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
