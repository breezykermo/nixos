{
	description = "Lachie's NixOS Flake";

	inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
    # TODO: do I need these?
    # flake-utils.url = "github:numtide/flake-utils";

    # For building from Python projects
    # poetry2nix.url = "github:nix-community/poetry2nix";

    # For building from Rust projects
    # naersk.url = "github:nix-community/naersk";
	};

	outputs = inputs@{
    nixpkgs, 
    home-manager, 
    # poetry2nix, 
    # naersk,
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
