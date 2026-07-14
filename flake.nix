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
    typst-flake,
    eilmeldung,
    ... }:
  let
    system = "x86_64-linux";

    # Custom package overlay, applied to the system pkgs via the
    # `nixpkgs.overlays` module option below.
    overlay = self: super: {
      kagimcp = self.python3Packages.callPackage ./pkgs/kagimcp {};
    };

    # Auto-discover machines: every DIRECTORY under ./machines/ is a machine
    # (framework, homework, dellxps). `base.nix`/`local-profile.nix` are regular
    # files and `modules/` is shared, so both are excluded by the directory + name
    # filter below. Each machine dir holds configuration.nix + hardware-configuration.nix
    # + vars.nix.
    machinesDir = ./machines;
    machineEntries = builtins.readDir machinesDir;
    machineNames = builtins.filter
      (name: machineEntries.${name} == "directory" && name != "modules")
      (builtins.attrNames machineEntries);

    # Build a full nixosSystem for one machine directory. There is no hardcoded
    # machine selection anymore: ALL machines are exposed as
    # `nixosConfigurations.<name>` and the box is chosen at build time with
    # `nixos-rebuild --flake .#<name>` (see the Justfile, which reads the gitignored
    # `machines/local-profile.nix` marker at deploy time).
    mkMachine = name:
      let
        machineVars = import ./machines/${name}/vars.nix;
        userName = machineVars.userName;

        # The machine name doubles as the profile that gates machine-specific
        # software and behaviour in shared modules (see `localProfile == "homework"`).
        localProfile = name;

        # Theme depends on localProfile, so it is resolved per machine.
        theme = import ./themes/default.nix { inherit (nixpkgs) lib; inherit localProfile; };
      in
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs userName machineVars localProfile; };
        modules = [
          { nixpkgs.overlays = [ overlay eilmeldung.overlays.default ]; }
          ./configuration.nix
          ./machines/base.nix
          ./machines/${name}/configuration.nix

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
  in
  {
    nixosConfigurations = builtins.listToAttrs
      (map (name: { inherit name; value = mkMachine name; }) machineNames);
  };
}
