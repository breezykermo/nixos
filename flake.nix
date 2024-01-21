{
	description = "Lachie's NixOS Flake";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		home-manager.url = "github:nix-community/home-manager";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";

		hyprland = {
			url = "github:hyprwm/Hyprland/v0.33.1";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		doomemacs = {
			url = "github:doomemacs/doomemacs";
			flake = false;
		};

	};

	outputs = inputs@{ nixpkgs, home-manager, ... }: {
		nixosConfigurations = {
			"nixos" = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = inputs; # Pass all input parameters to submodules
				modules = [
					# NetworkManager, time zone, i18n, X11, pulseaudio, user accounts, SSH
					./nixos/configuration.nix
					# Use home-manager to configure different users
					home-manager.nixosModules.home-manager
					{
						home-manager = {
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
