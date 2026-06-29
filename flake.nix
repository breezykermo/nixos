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
      url = "github:breezykermo/typst-flake";
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
    # eilmeldung - TUI RSS reader
    eilmeldung = {
      url = "github:christo-auer/eilmeldung";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    nixpkgs,
    home-manager,
    naersk,
    orion-browser,
    typst-flake,
    eilmeldung,
    ... }:
  let
    system = "x86_64-linux";

    # Switch machines by changing this ONE line. It must be a hardcoded string, NOT a
    # read of a gitignored file: `nixos-rebuild --flake .` evaluates only git-tracked
    # files, so a gitignored selector (e.g. machines/local-profile.nix) is invisible at
    # eval time and silently falls back. Keep this set to the machine you are on.
    selectedMachine = "homework";
    # selectedMachine = "framework";
    # selectedMachine = "dellxps";

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
        { nixpkgs.overlays = [ overlay eilmeldung.overlays.default ]; }
        ./configuration.nix
        ./machines/base.nix
        ./machines/${selectedMachine}/configuration.nix

        home-manager.nixosModules.home-manager {
          # system wide
          programs.fish.enable = true;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs system userName naersk machineVars theme localProfile eilmeldung; };

            users."${userName}" = import ./home-manager;
          };
        }
      ];
    };
  };
}
