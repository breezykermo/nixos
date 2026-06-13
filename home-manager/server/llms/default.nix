{ config, pkgs, lib, inputs, system, localProfile, ... }:
let
  abacus = pkgs.callPackage ./abacus.nix { };
  beads = pkgs.callPackage ./beads.nix { };

  # Local models only exist on homework (128GB Strix Halo box). See
  # machines/homework/configuration.nix for the ollama / model setup.
  isHomework = localProfile == "homework";

  # claude-code-router exposes an Anthropic-compatible endpoint backed by the local
  # ollama OpenAI-compatible API, so Claude Code can talk to local models. Launch
  # with `ccr code` (aliased to `ccl`), then pick a model in-session with
  # `/model ollama,<name>`. Routes below set sensible defaults per task class.
  ccrConfig = {
    LOG = false;
    Providers = [
      {
        name = "ollama";
        api_base_url = "http://localhost:11434/v1/chat/completions";
        api_key = "ollama"; # ollama ignores the key, but CCR requires the field
        models = [
          "qwen3-coder:30b"
          "gpt-oss:120b"
          "MichelRosselli/GLM-4.5-Air:Q5_K_M"
        ];
      }
    ];
    Router = {
      default = "ollama,qwen3-coder:30b";     # agentic workhorse with reliable tool calls
      background = "ollama,qwen3-coder:30b";   # cheap/fast side tasks
      think = "ollama,gpt-oss:120b";           # heavier reasoning
      longContext = "ollama,gpt-oss:120b";
      longContextThreshold = 24000;
    };
  };
  typst-author-skill = pkgs.fetchFromGitHub {
    owner = "apcamargo";
    repo = "typst-author";
    rev = "main";
    sha256 = "0h9gbb76mhlgjpi42b9vj4qckf52msv88dgzlqm3ql7vdpa7vm9z";
  };
  rheo-author-skill = pkgs.fetchFromGitHub {
    owner = "freecomputinglab";
    repo = "rheo-author";
    rev = "main";
    sha256 = "sha256-eZeW1GCdkqr4zWkYTj4K2uLCvh8rPmEs+bH0mULmums=";
  };
  agentic-jujutsu-skill = pkgs.fetchFromGitHub {
    owner = "ruvnet";
    repo = "agentic-flow";
    rev = "main";
    sha256 = "sha256-P9V91G37UDwqpv81hLauorjJMJE7LUHilY/Cas5aL0E=";
  };
in
{
  home.file = {
    ".claude/skills/typst-author".source = typst-author-skill;
    ".claude/skills/rheo-author".source = rheo-author-skill;
    ".claude/skills/agentic-jujutsu".source = "${agentic-jujutsu-skill}/packages/agentic-jujutsu";
    ".claude/skills/bonsai-author".source = ./skills/bonsai-author;
  } // lib.optionalAttrs isHomework {
    ".claude-code-router/config.json".text = builtins.toJSON ccrConfig;
  };

  home.shellAliases = {
    ccb = "claudebox --allow-ssh-agent";
  } // lib.optionalAttrs isHomework {
    ccl = "ccr code"; # Claude Code routed to local ollama models
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
  ] ++ lib.optionals isHomework [
    inputs.llm-agents.packages.${system}.claude-code-router
  ];

  home.sessionVariables = {
    # Claude code
    DISABLE_TELEMETRY = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
  };
}
