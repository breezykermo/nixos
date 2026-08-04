{
  pkgs,
  lib,
  theme,
  ...
}: let
  # Shared harness resources.
  pellucid = false;
  falconryRepo = "/home/lox/code/_konrad/falconry";
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
    inherit falconryRepo globalMemory pinnedSkills;
  };

  home.packages = [beads abacus];
}
