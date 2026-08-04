{
  config,
  pkgs,
  lib,
  theme,
  ...
}: let
  # Shared harness resources.
  pellucid = false;
  falconryRepo = "/home/lox/code/_konrad/falconry";
  # Complete portable Falconry surface. Keep explicit: pure flake evaluation
  # cannot discover directories from the live out-of-store checkout above.
  falconrySkillNames = [
    "bead-quality"
    "beads-plan-mode"
    "caveman"
    "falconry-hack"
    "falconry-slip"
    "falconry-workflow"
    "jj-workspaces"
    "nixos-machine"
  ];
  mkFalconrySkillLinks = destination:
    lib.listToAttrs (map (name: {
      name = "${destination}/${name}";
      value.source = config.lib.file.mkOutOfStoreSymlink "${falconryRepo}/skills/${name}";
    }) falconrySkillNames);
  globalMemory =
    builtins.readFile ./global-core.md
    + lib.optionalString pellucid ("\n---\n\n" + builtins.readFile ./pellucid.md);

  pins = builtins.fromJSON (builtins.readFile ../../../pins.json);
  pinnedSkills = lib.mapAttrs (_: pkgs.fetchFromGitHub) pins;

  abacus = pkgs.callPackage ./abacus.nix {inherit theme;};
  beads = pkgs.callPackage ./beads.nix {};
in {
  imports = [
    ./claude-code.nix
    ./codex.nix
    ./pi.nix
    ./qwen-code.nix
  ];

  _module.args.llmShared = {
    inherit globalMemory mkFalconrySkillLinks pinnedSkills;
  };

  home.packages = [beads abacus];
}
