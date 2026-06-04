{ config, pkgs, lib, inputs, system, ... }:
let
  abacus = pkgs.callPackage ./abacus.nix { };
  beads = pkgs.callPackage ./beads.nix { };
  typst-author-skill = pkgs.fetchFromGitHub {
    owner = "apcamargo";
    repo = "typst-author";
    rev = "main";
    sha256 = "01q5z7b5wc5bgzfkkmqqz27ycqcx01x3l8zp6b7md3lqd986pj09";
  };
  rheo-author-skill = pkgs.fetchFromGitHub {
    owner = "freecomputinglab";
    repo = "rheo-author";
    rev = "main";
    sha256 = "0x8qra9ifbz041nzzdkcyx8rglj0z4jzjvay7fj2sdsizxz55dr8";
  };
  agentic-jujutsu-skill = pkgs.fetchFromGitHub {
    owner = "ruvnet";
    repo = "agentic-flow";
    rev = "main";
    sha256 = "1vhidz1q72d7hadwb3jmclh5hx34w4hsr3s03bxdcmsf2a97niwr";
  };
in
{
  home.file = {
    ".claude/skills/typst-author".source = typst-author-skill;
    ".claude/skills/rheo-author".source = rheo-author-skill;
    ".claude/skills/agentic-jujutsu".source = "${agentic-jujutsu-skill}/packages/agentic-jujutsu";
  };

  home.shellAliases = {
    ccb = "claudebox --allow-ssh-agent";
  };

  programs.fish.functions.glm = ''
    set -x ANTHROPIC_BASE_URL https://api.z.ai/api/anthropic
    set -x ANTHROPIC_AUTH_TOKEN (pass show ai/zai)
    set -x ANTHROPIC_MODEL glm-4.5
    claudebox --allow-ssh-agent $argv[1]
  '';

  home.packages = [
    beads
    abacus
    inputs.llm-agents.packages.${system}.claude-code
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
