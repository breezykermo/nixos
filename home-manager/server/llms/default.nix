{
  pkgs,
  lib,
  theme,
  ...
}: let
  # Shared harness resources.
  pellucid = false;
  # Complete portable Soroban surface. Keep explicit: pure flake evaluation
  # cannot discover directories inside the fetched pin below.
  sorobanSkillNames = [
    "bead-quality"
    "beads-plan-mode"
    "caveman"
    "jj-workspaces"
    "soroban-hack"
    "soroban-slip"
    "soroban-workflow"
  ];
  mkSorobanSkillLinks = destination:
    lib.listToAttrs (map (name: {
      name = "${destination}/${name}";
      value.source = "${pinnedSkills.soroban}/skills/${name}";
    }) sorobanSkillNames);
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
    inherit globalMemory mkSorobanSkillLinks pinnedSkills;
  };

  home.packages = [beads abacus];
}
