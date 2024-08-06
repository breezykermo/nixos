{
	description = "Lachie's NixOS Flake";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
    };

		# rycee-nurpkgs = {
		# 	url = gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons;
		# 	inputs.nixpkgs.follows = "nixpkgs";
		# };

		# nix-doom-emacs = {
		# 	url = "github:nix-community/nix-doom-emacs";
		# 	inputs.nixpkgs.follows = "nixpkgs";
		# };
	};

	outputs = inputs@{ nixpkgs, home-manager, poetry2nix, ... }:
	let 
		system = "x86_64-linux";
	in
	{
		nixosConfigurations.loxnix = nixpkgs.lib.nixosSystem {
			inherit system; 
			modules = [
				# hardware, NetworkManager, time zone, i18n, X11, pulseaudio, user accounts, SSH
				./nixos/configuration.nix

				# Use home-manager to configure different users
				home-manager.nixosModules.home-manager {
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						extraSpecialArgs = { inherit inputs system poetry2nix; };

						users.alice = import ./home-manager;
					};
				}

				./machines/dellxps.nix
			];
		};
	};
}
