{ userName, pkgs, ... }:

{
	imports = [
		./server
		./desktop
	];

	home.username = userName;
	home.homeDirectory = "/home/${userName}";
	home.stateVersion = "23.11";
	home.enableNixpkgsReleaseCheck = false;
	programs.home-manager.enable = true;
}
