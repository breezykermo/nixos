{
	description = "Lachie's NixOS Flake";

  inputs = {
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
    ... }:
  let 
		system = "x86_64-linux";
	in
	{
		nixosConfigurations.loxnix = nixpkgs.lib.nixosSystem {
			inherit system; 
      specialArgs = { userName ? "alice" }: { inherit userName; };
			modules = [
				# hardware, NetworkManager, time zone, i18n, X11, pulseaudio, user accounts, SSH
				./nixos/configuration.nix

				# Use home-manager to configure different users
        ({ userName, ... }: {
          home-manager.nixosModules.home-manager = {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs system; };

              users."${userName}" = import ./home-manager;
            };
          };
        })

				./machines/dellxps.nix
			];
		};
	};
}
