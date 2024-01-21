{
	description = "Lachie's NixOS Flake";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		home-manager.url = "github:nix-community/home-manager";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";
		hyprland.url = "github:hyprwm/Hyprland";
		# diosevka.url = "sourcehut:~nomisiv/diosevka";
		neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
	};

	outputs = inputs@{ nixpkgs, home-manager, ... }: {
		nixosConfigurations = {
			"nixos" = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = inputs; # Pass all input parameters to submodules
				modules = [
					# NetworkManager, time zone, i18n, X11, pulseaudio, user accounts, SSH
					./nixos/configuration.nix
					home-manager.nixosModules.home-manager
					# hyprland.nixosModules.default
					{
						home-manager = {
							useGlobalPkgs = true;
							useUserPackages = true;
							users.alice = import ./home-manager;
							# sharedModules = [
							# 	{home.stateVersion = "23.05";}
							# 	./home-manager
							# ];
						};
					}
					./machines/thinkpad.nix
				];
			};
		};
	};
}
