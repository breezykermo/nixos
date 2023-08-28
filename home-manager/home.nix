{ config, pkgs, ... }:

{
	home.username = "alice";
	home.homeDirectory = "/home/alice";
	
	programs.git = {
		enable  = true;
		userName = "breezykermo";
		userEmail = "lachlankermode@live.com";
	};

	home.packages = with pkgs; [
		# archives
		zip
		xz
		unzip

		# system 
		file
		which
		strace
		lsof
		pciutils
		usbutils

		# utils
		jq
		exa
		fzf
		gawk
		tree

		# networking
		nmap
		ldns
	];

	programs.alacritty = {
		enable = true;
		settings = {
			env.TERM = "xterm-256color";
			font = {
				size = 12;
				draw_bold_text_with_bright_colors = true;
			};
			scrolling.multiplier = 5;
			selection.save_to_clipboard = true;
		};
	};

	programs.bash = {
		enable = true;
		enableCompletion = true;
		shellAliases = {};
	};
	home.stateVersion = "23.05";

	programs.home-manager.enable = true;
}
