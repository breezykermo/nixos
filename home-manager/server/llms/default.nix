{ config, pkgs, lib, inputs, system, localProfile, ... }:
let
  abacus = pkgs.callPackage ./abacus.nix { };
  beads = pkgs.callPackage ./beads.nix { };

  # The packaged claude-code-router renames dist/cli.js to bin/ccr and drops
  # dist/index.html, but: (1) `ccr code`'s lazy auto-start path hardcodes a
  # respawn via `node <dir-of-ccr>/cli.js start` — that file doesn't exist, so
  # the spawn silently fails and `ccr code` just burns its ~11s wait before
  # reporting "Service startup timeout"; (2) `ccr ui`'s web dashboard serves
  # static files from `join(__dirname, "..", "dist")`, i.e. `<prefix>/dist/`
  # alongside `bin/`, which 404s without index.html there. Node resolves
  # `__dirname` to the realpath of the running script, so a symlink back into the
  # original (cli.js-less) store path doesn't help — the binary must be a real
  # copy, with cli.js copied alongside it and index.html one level up.
  claude-code-router =
    let orig = inputs.llm-agents.packages.${system}.claude-code-router;
    in pkgs.runCommand "claude-code-router-cli-fix" { } ''
      mkdir -p $out/bin $out/dist
      cp ${orig}/bin/ccr $out/bin/ccr
      cp ${orig}/bin/tiktoken_bg.wasm $out/bin/tiktoken_bg.wasm
      cp ${orig.src}/dist/index.html $out/dist/index.html
      cp $out/bin/ccr $out/bin/cli.js
      chmod +x $out/bin/ccr $out/bin/cli.js
    '';

  # Local models only exist on homework (128GB Strix Halo box). See
  # machines/homework/configuration.nix for the ollama / model setup.
  isHomework = localProfile == "homework";

  # claude-code-router exposes an Anthropic-compatible endpoint backed by the local
  # ollama OpenAI-compatible API, so Claude Code can talk to local models. Invoke
  # it directly with `ccr code`; pick a model in-session with
  # `/model ollama,<name>` (see `allmodels` below for the full list). For z.ai
  # (GLM) cloud models, use `glm` instead, which talks to z.ai's own
  # Anthropic-compatible endpoint directly (no router involved). For your Claude
  # Pro/Max subscription models, use `claude`. Routes below set sensible defaults
  # per task class.
  ccrConfig = {
    LOG = false;
    # Claude Code's global `effortLevel` setting makes it send a
    # `reasoning_effort` field on every request, including to non-Claude
    # models. Ollama's /v1/chat/completions rejects this for qwen3-coder:30b
    # (no thinking mode) with "does not support thinking". This custom
    # transformer strips reasoning/thinking fields before they reach Ollama.
    # https://github.com/musistudio/claude-code-router/issues/972
    transformers = [
      { path = "${config.home.homeDirectory}/.claude-code-router/transformers/strip-reasoning-params.js"; }
    ];
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
        transformer = {
          "qwen3-coder:30b" = {
            use = [ "strip-reasoning-params" ];
          };
        };
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
    ".claude-code-router/transformers/strip-reasoning-params.js".source = ./transformers/strip-reasoning-params.js;
    ".config/zai-models.json".text = builtins.toJSON {
      models = [
        "GLM-5.2"
        "GLM-5.1"
        "GLM-5"
        "GLM-5-Turbo"
        "GLM-4.7"
        "GLM-4.6"
        "GLM-4.5"
        "GLM-4.5-Air"
        "GLM-5V-Turbo"
        "GLM-4.6V"
      ];
    };
  };

  home.shellAliases = {
    ccb = "claudebox --allow-ssh-agent";
  };

  programs.fish.functions = {
    # `glm` points claude directly at z.ai's native Anthropic-compatible
    # endpoint, so GLM models get full feature parity (e.g. Plan Mode) under
    # your z.ai plan — no router involved. Available on all machines; requires
    # `pass show ai/zai` to resolve (i.e. the secret + gpg key must be present
    # on this machine).
    glm = ''
      set -x ANTHROPIC_BASE_URL https://api.z.ai/api/anthropic
      set -x ANTHROPIC_AUTH_TOKEN (pass show ai/zai)
      set -x ANTHROPIC_MODEL glm-4.5
      command claude $argv
    '';
  } // lib.optionalAttrs isHomework {
    # `claude` runs the real binary unmodified, against your Claude Pro/Max
    # subscription login.
    claude = ''
      command claude $argv
    '';

    # Lists "provider,model" strings usable with `/model` inside `ccr code`.
    # Shows both ollama models (from config) and z.ai models (from config file).
    allmodels = ''
      echo "# Ollama models (via ccr code):"
      jq -r '.Providers[] | select(.name == "ollama") | .name as $p | .models[] | "\($p),\(.)"' ~/.claude-code-router/config.json 2>/dev/null || echo "# No ollama config found"
      echo ""
      echo "# z.ai models (via glm wrapper):"
      jq -r '.models[] | "zai,\(.)"' ~/.config/zai-models.json 2>/dev/null || echo "# No z.ai models config found"
    '';
  };

  home.packages = [
    beads
    abacus
    inputs.llm-agents.packages.${system}.claude-code
    inputs.llm-agents.packages.${system}.claudebox
  ] ++ lib.optionals isHomework [
    claude-code-router
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
