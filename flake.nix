{
  description = "Lachie's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # For more easily installing and configuring software
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The best terminal emulator
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # For building Rust packages
    naersk.url = "github:nix-community/naersk";
    # Bene - writing tools
    bene = {
      url = "github:breezykermo/bene/feat/adds-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # AI coding agent packages (claude-code, claude-code-router, etc.)
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Typst - modern typesetting system
    typst-flake = {
      url = "github:typst/typst-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # tuicr - code review TUI with vim keybindings
    tuicr = {
      url = "github:agavra/tuicr/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # concord - TUI client for Discord
    concord = {
      url = "github:chojs23/concord";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Orion Browser - privacy-focused browser
    orion-browser = {
      url = "github:dokokitsune/orion-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    nixpkgs,
    home-manager,
    naersk,
    orion-browser,
    ... }:
  let
    system = "x86_64-linux";

    # Which machine config to build. This is read from the gitignored, per-machine
    # file ./machines/local-profile.nix, which contains the machine name as a string
    # (e.g. "homework"). Machines without that file -- a fresh checkout and the
    # "framework" laptop -- default to "framework".
    #
    # To target a different machine, create the file with its name, e.g.:
    #   echo '"homework"' > machines/local-profile.nix   # or "dellxps"
    selectedMachine = if builtins.pathExists ./machines/local-profile.nix
      then import ./machines/local-profile.nix
      else "framework";

    # Import machine-specific variables
    machineVars = import ./machines/${selectedMachine}/vars.nix;
    userName = machineVars.userName;

    # The machine name doubles as the profile that gates machine-specific software
    # and behaviour in shared modules (see the `localProfile == "homework"` checks).
    localProfile = selectedMachine;

    # Import theme once and pass to all modules
    theme = import ./themes/default.nix { inherit (nixpkgs) lib; inherit localProfile; };

    # Custom package overlay, applied to the system pkgs via the
    # `nixpkgs.overlays` module option below.
    overlay = self: super: {
      kagimcp = self.python3Packages.callPackage ./pkgs/kagimcp {};
    };
  in
  {
    nixosConfigurations.loxnix = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs userName machineVars localProfile; };
      modules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./configuration.nix
        ./machines/base.nix
        ./machines/${selectedMachine}/configuration.nix

        home-manager.nixosModules.home-manager {
          # system wide
          programs.fish.enable = true;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs system userName naersk machineVars theme localProfile; };

            users."${userName}" = import ./home-manager;
          };
        }
      ];
    };
  };
}
