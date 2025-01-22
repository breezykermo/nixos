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
    userName = "lox";
    # userName = "alice";
  in
  {
    nixosConfigurations.loxnix = nixpkgs.lib.nixosSystem {
      inherit system; 
      specialArgs = { inherit userName; };
      modules = [
        ./configuration.nix
        ./machines/framework/configuration.nix
        # ./machines/dellxps/configuration.nix

        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs system userName; };

            users."${userName}" = import ./home-manager;
          };
        }
      ];
    };
  };
}
