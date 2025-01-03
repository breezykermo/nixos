{
	description = "Lachie's NixOS Flake";

  inputs = {
    # NOTE: Determinate seems nice. But I'm not yet sure why/how I would use it.
    # determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
    # nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
	};

  outputs = inputs@{
    nixpkgs, 
    home-manager, 
    # determinate,
    ... }:
  let 
		system = "x86_64-linux";
	in
	{
		nixosConfigurations.loxnix = nixpkgs.lib.nixosSystem {
			inherit system; 
			modules = [
				# hardware, NetworkManager, time zone, i18n, X11, pulseaudio, user accounts, SSH
				./nixos/configuration.nix

        # determinate.nixosModules.default

				# Use home-manager to configure different users
				home-manager.nixosModules.home-manager {
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						extraSpecialArgs = { inherit inputs system; };

						users.alice = import ./home-manager;
					};
				}

				./machines/dellxps.nix
			];
		};
	};
}
