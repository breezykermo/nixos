{ userName, ... }:

{
	# secrets = builtins.fromJSON (builtins.readFile "${self}/secrets/secrets.json");
	imports = [
		./server
		./desktop
	];

	home.username = userName;
	home.homeDirectory = "/home/${userName}";
	home.stateVersion = "23.11";
	programs.home-manager.enable = true;
}
