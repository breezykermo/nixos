{ ... }:

{
	# secrets = builtins.fromJSON (builtins.readFile "${self}/secrets/secrets.json");
	imports = [
		./server
		./desktop
	];

	home.username = "alice";
	home.homeDirectory = "/home/alice";
	home.stateVersion = "23.11";
	programs.home-manager.enable = true;
}
