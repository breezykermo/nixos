{pkgs, config, ...}: {
	services = {
		keybase.enable = true;
	};
	home.packages = with pkgs; [
		neofetch
		lazygit		# git tui client
		# pandoc		# document processor
		tectonic	# LaTeX compilation
		pdftk     # pdf manipulation

		# archives
		zip
		xz

		# networking tools
		# mtr				# A network diagnostic tool
		# dnsutils	# `dig` + `nslookup`
		# ldns			# replacement of `dig`, it provide the command `drill`
		nmap			# A utility for network discovery and security auditing

		# Text Processing
		# Docs: https://github.com/learnbyexample/Command-line-text-processing
		gawk			# GNU awk, a pattern scanning and processing language
		ripgrep		# recursively searches directories for a regex pattern
		sad				# CLI search and replace, with diff preview 
		delta			# A viewer for git and diff output
		ripgrep   # `rg` is a better grep
		fd        # `fd` is a better find
		jq				# A lightweight and flexible command-line JSON processor

		file
		which
		tree
		gnupg

		# fonts
		fira-code
		fira-code-symbols
		font-awesome
		noto-fonts
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
	};

	programs = {
		# email in the terminal
		aerc.enable = true;

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

		# file directory navigation
		broot = {
			enable = true;
			enableFishIntegration = true;
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
		
		jujutsu = {
			enable = true;
			settings = {
				user = {
					name = "Lachlan Kermode";
					email = "hi@ohrg.org";
				};
			};
			enableFishIntegration = true;
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

		dircolors = {
			enable = true;
		};

		command-not-found.enable = false;

		htop = {
			enable = true;
			settings = {
				fields = with config.lib.htop.fields; [
					PID
					USER
					PRIORITY
					NICE
					M_SIZE
					M_RESIDENT
					M_SHARE
					STATE
					PERCENT_CPU
					PERCENT_MEM
					TIME
					COMM
				];
				sort_key = 46;
				sort_direction = 1;
				hide_kernel_threads = 1;
				hide_userland_threads = 0;
				shadow_other_users = 0;
				show_thread_names = 0;
				show_program_path = 1;
				highlight_base_name = 0;
				highlight_megabytes = 1;
				highlight_threads = 1;
				highlight_changes = 0;
				highlight_changes_delay_secs = 5;
				find_comm_in_cmdline = 1;
				strip_exe_from_cmdline = 1;
				show_merged_command = 0;
				tree_view = 1;
				header_margin = 1;
				detailed_cpu_time = 0;
				cpu_count_from_one = 0;
				show_cpu_usage = 1;
				show_cpu_frequency = 0;
				show_cpu_temperature = 0;
				degree_fahrenheit = 0;
				update_process_names = 0;
				account_guest_in_cpu_meter = 0;
				color_scheme = 0;
				enable_mouse = 1;
				delay = 15;
				# left_meters = with config.lib.htop; leftMeters [
				#  (bar "LeftCPUs2")
				#  (bar "Memory")
				#  (bar "Swap)
				# ];
				# right_meters= with config.lib.htop; rightMeters [
				# 	(bar "RightCPUs2")
				# 	(bar "Tasks")
				# 	(bar "LoadAverage")
				# 	(bar "Uptime")
				# ];
			};
		};
	};
}
