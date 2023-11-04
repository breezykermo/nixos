{ ... }:

{
	imports = [
		./server
		./desktop
	];
	home = {
		username = "alice";
		homeDirectory = "/home/alice";
	};

	xdg = {
		userDirs = {
			enable = true;
			desktop = "$HOME/.desktop";
			download = "$HOME/downloads";
		};
	};

	home.stateVersion = "23.05";

	programs.home-manager.enable = true;
}
