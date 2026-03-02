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

  # Create wrapper script for claude-code-router that reads from pass
  claude-code-router-wrapper = pkgs.writeShellScriptBin "claude-code-router-wrapper" ''
    #!${pkgs.bash}/bin/bash
    # Read API keys from pass
    export ANTHROPIC_API_KEY=$(${pkgs.pass}/bin/pass show ai/anthropic 2>/dev/null || echo "")
    export ZAI_API_KEY=$(${pkgs.pass}/bin/pass show ai/zai 2>/dev/null || echo "")

    # Start the router
    exec ${inputs.llm-agents.packages.${system}.claude-code-router}/bin/claude-code-router "$@"
  '';
in
{
  home.file = {
    ".claude/skills/typst-author".source = typst-author-skill;
    ".claude/skills/agentic-jujutsu/SKILL.md".source = ./skills/agentic-jujutsu/SKILL.md;
  };

  home.shellAliases = {
    ccb = "claudebox --allow-ssh-agent";
    cc = "claude";  # Uses router by default
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

  # Claude Code Router systemd service
  systemd.user.services.claude-code-router = {
    Unit = {
      Description = "Claude Code Router - Dynamic LLM switching proxy";
      After = "network.target";
    };
    Service = {
      Type = "simple";
      ExecStart = "${claude-code-router-wrapper}/bin/claude-code-router-wrapper";
      Restart = "always";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Deploy router config
  xdg.configFile."claude-code-router/config.json".source = ./router-config.json;
}
