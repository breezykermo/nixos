{
  description = "Lachie's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # For more easily installing and configuring software
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The best terminal emulator
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    # For building Rust packages
    naersk.url = "github:nix-community/naersk";
  };

  outputs = inputs@{
    nixpkgs, 
    home-manager, 
    naersk,
    ... }:
  let 
    system = "x86_64-linux";
    # userName = "lox";
    userName = "alice";
  in
  {
    nixosConfigurations.loxnix = nixpkgs.lib.nixosSystem {
      inherit system; 
      specialArgs = { inherit userName; };
      modules = [
        ./configuration.nix
        # ./machines/framework/configuration.nix
        ./machines/dellxps/configuration.nix

        home-manager.nixosModules.home-manager {
          # system wide
          programs.fish.enable = true;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs system userName naersk; };

            users."${userName}" = import ./home-manager;
          };
        }
      ];
    };
  };
}
