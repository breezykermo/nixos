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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Typst from upstream main branch
    typst = {
      url = "github:typst/typst";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # For building Rust packages
    naersk.url = "github:nix-community/naersk";
    # Beads - AI coding agent issue tracker
    beads = {
      url = "github:steveyegge/beads";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Terminal-based diff viewer with file tree navigation
    ftdv = {
      url = "github:breezykermo/ftdv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Rheo
    rheo = {
      url = "git+ssh://git@github.com/breezykermo/rheo.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    nixpkgs,
    home-manager,
    naersk,
    ... }:
  let
    system = "x86_64-linux";

    # Switch machines by changing this ONE line!
    selectedMachine = "framework";
    # selectedMachine = "dellxps";

    # Import machine-specific variables
    machineVars = import ./machines/${selectedMachine}/vars.nix;
    userName = machineVars.userName;
  in
  {
    nixosConfigurations.loxnix = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit userName machineVars; };
      modules = [
        ./configuration.nix
        ./machines/base.nix
        ./machines/${selectedMachine}/configuration.nix

        home-manager.nixosModules.home-manager {
          # system wide
          programs.fish.enable = true;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs system userName naersk machineVars; };

            users."${userName}" = import ./home-manager;
          };
        }
      ];
    };
  };
}
