{
	description = "Lachie's NixOS Flake";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		home-manager.url = "github:nix-community/home-manager";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";

		rycee-nurpkgs = {
			url = gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons;
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { nixpkgs, home-manager, ... }@inputs: {
		nixosConfigurations = {
			"nixos" = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux"; 
				specialArgs = { inherit inputs; }; # Pass all input parameters to submodules
				modules = [
					# NetworkManager, time zone, i18n, X11, pulseaudio, user accounts, SSH
					./nixos/configuration.nix
					# Use home-manager to configure different users
					home-manager.nixosModules.home-manager
					{
						home-manager = {
							useGlobalPkgs = true;
							useUserPackages = true;
							extraSpecialArgs = { inherit inputs; };
							users.alice = import ./home-manager;
						};
					}
					./machines/thinkpad.nix
				];
			};
		};
	};
}
