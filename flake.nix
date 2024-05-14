{
	description = "Lachie's NixOS Flake";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		home-manager.url = "github:nix-community/home-manager";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";

		# rycee-nurpkgs = {
		# 	url = gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons;
		# 	inputs.nixpkgs.follows = "nixpkgs";
		# };

		# nix-doom-emacs = {
		# 	url = "github:nix-community/nix-doom-emacs";
		# 	inputs.nixpkgs.follows = "nixpkgs";
		# };
	};

	outputs = inputs@{ nixpkgs, home-manager, ... }:
	let 
		system = "x86_64-linux";
	in
	{
		nixosConfigurations = {
			"nixlox" = nixpkgs.lib.nixosSystem {
				system = system; 
				# specialArgs = { inherit inputs; }; # Pass all input parameters to submodules
				modules = [
					# NetworkManager, time zone, i18n, X11, pulseaudio, user accounts, SSH
					./nixos/configuration.nix
					# Use home-manager to configure different users
					home-manager.nixosModules.home-manager
					{
						home-manager = {
							# see https://blog.nobbz.dev/2022-12-12-getting-inputs-to-modules-in-a-flake/
							extraSpecialArgs = { inherit inputs system; };

							useGlobalPkgs = true;
							useUserPackages = true;
							users.alice = import ./home-manager;
						};
					}
					./machines/thinkpad.nix
				];
			};
		};
	};
}
