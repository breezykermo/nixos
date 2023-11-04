{
	description = "Lachie's NixOS Flake";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		home-manager.url = "github:nix-community/home-manager";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    raw-browser = {
      url = "sourcehut:~nomisiv/raw-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    diosevka.url = "sourcehut:~nomisiv/diosevka";
	};

	outputs = inputs@{ nixpkgs, home-manager, ... }: {
		nixosConfigurations = {
			"nixos" = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					./nixos/configuration.nix
					home-manager.nixosModules.home-manager
          hyprland.nixosModules.default
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [
                {home.stateVersion = stateVersion;}
                ./home-manager
                hyprland.homeManagerModules.default
              ];
            };
          }
					./machines/thinkpad.nix;
				];
			};
		};
	};
}
