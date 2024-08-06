{ ... }:

{
	# secrets = builtins.fromJSON (builtins.readFile "${self}/secrets/secrets.json");
	imports = [
		./server
		./desktop
	];

  # virtualisation: see https://nixos.wiki/wiki/Virt-manager
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

	home.username = "alice";
	home.homeDirectory = "/home/alice";
	home.stateVersion = "23.11";
	programs.home-manager.enable = true;
}
