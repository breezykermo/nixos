{ config, pkgs, lib, inputs, system, ... }:
let
  abacus = pkgs.callPackage ./abacus.nix { };
  beads = pkgs.callPackage ./beads.nix { };
  typst-author-skill = pkgs.fetchFromGitHub {
    owner = "apcamargo";
    repo = "typst-author";
    rev = "9e4ace023b255ffbd9dacd26fe27665eef9c6d4b";
    sha256 = "0nl29qhn4i5x7xlai5782zga6xppqzd84i6vv53qz65y105gwahl";
  };
in
{
  home.file = {
    ".claude/skills/typst-author".source = typst-author-skill;
    ".claude/skills/agentic-jujutsu/SKILL.md".source = ./skills/agentic-jujutsu/SKILL.md;
  };

  home.shellAliases = {
    ccb = "claudebox --allow-ssh-agent";
  };

  home.packages = [
    beads
    abacus
    inputs.llm-agents.packages.${system}.claude-code
    inputs.llm-agents.packages.${system}.claude-code-router
    inputs.llm-agents.packages.${system}.claudebox
    inputs.llm-agents.packages.${system}.ccusage
  ];

  home.sessionVariables = {
    # Claude code
    DISABLE_TELEMETRY = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
  };
}
