{ ... }:

{
	imports = [
		./server
    # ./desktop
	];
	home = {
		username = "alice";
		homeDirectory = "/home/alice";
	};

	home.stateVersion = "23.05";

	programs.home-manager.enable = true;
}
