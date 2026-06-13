{ config, pkgs, lib, inputs, system, localProfile, ... }:
let
  abacus = pkgs.callPackage ./abacus.nix { };
  beads = pkgs.callPackage ./beads.nix { };

  # Local models only exist on homework (128GB Strix Halo box). See
  # machines/homework/configuration.nix for the ollama / model setup.
  isHomework = localProfile == "homework";

  # claude-code-router exposes an Anthropic-compatible endpoint backed by the local
  # ollama OpenAI-compatible API, so Claude Code can talk to local models. The
  # `glm` fish function (below) launches it via `ccr code`; pick a model
  # in-session with `/model ollama,<name>` or `/model zai,glm-4.6`. For your
  # Claude Pro/Max subscription models (not available through the router), use
  # `claude` instead. Routes below set sensible defaults per task class.
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
      {
        # z.ai (GLM) cloud models, reachable in-session with `/model zai,glm-4.6`.
        # OpenAI-compatible endpoint (CCR providers are OpenAI-format). The key is
        # interpolated from $ZAI_API_KEY in the ccr process env — exported by the
        # `claude` wrapper below from `pass` — so no secret lands in the nix store.
        name = "zai";
        api_base_url = "https://api.z.ai/api/paas/v4/chat/completions";
        api_key = "$ZAI_API_KEY";
        models = [ "glm-4.6" "glm-4.5" ];
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
  };

  programs.fish.functions = lib.optionalAttrs isHomework {
    # Wrap `ccr` so ZAI_API_KEY is set for any invocation that might (re)start
    # the router service — e.g. a manual `ccr start`. The router interpolates
    # "$ZAI_API_KEY" from its own process env once, when the long-lived service
    # (re)starts; if that process never had the var set, the zai provider's key
    # stays as the literal unexpanded string and its models are unusable/missing
    # from `/model`.
    ccr = ''
      set -x ZAI_API_KEY (pass show ai/zai)
      command ccr $argv
    '';

    # `claude` runs the real binary unmodified, against your Claude Pro/Max
    # subscription login.
    claude = ''
      command claude $argv
    '';

    # `glm` routes through claude-code-router so both ollama and z.ai models are
    # available (switch in-session with `/model ollama,<name>` or `/model zai,glm-4.6`).
    # `ccr code` overrides ANTHROPIC_AUTH_TOKEN/ANTHROPIC_BASE_URL, so subscription
    # models aren't reachable this way — use `claude` for those instead. `ccr code`
    # starts the ccr server on first use (lazy — no boot service); the first start
    # can take a few seconds, after which the service stays up for subsequent
    # invocations.
    glm = ''
      ccr code $argv
    '';
  };

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
  } // lib.optionalAttrs isHomework {
    # Where ollama stores models (see machines/homework). Set here as a session
    # variable so it's exported to fish, tmux panes, and non-interactive contexts
    # alike (home-manager sources hm-session-vars in config.fish).
    OLLAMA_MODELS = "${config.home.homeDirectory}/data/ollama/models";
  };
}
