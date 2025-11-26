{ userName, pkgs, ... }:

{
	# secrets = builtins.fromJSON (builtins.readFile "${self}/secrets/secrets.json");
  # TODO: add maestral.ini with excluded files etc
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
