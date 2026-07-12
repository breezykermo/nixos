{ config, pkgs, lib, inputs, system, localProfile, ... }:
let
  abacus = pkgs.callPackage ./abacus.nix { };
  beads = pkgs.callPackage ./beads.nix { };

  # claude-code-router v3 ships a proper npm layout: bin/ccr is a wrapper that
  # execs the real dist/main/cli.js, so the old cli-fix hack (copying cli.js/
  # index.html/tiktoken_bg.wasm around a broken layout) is no longer needed.
  # `ccr code` respawn (`node <__dirname>/cli.js start`) and `ccr ui`'s static
  # serve (`resolve(__dirname,"..","renderer")`) both resolve correctly here.
  claude-code-router = inputs.llm-agents.packages.${system}.claude-code-router;

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
  # Skill source pins live in pins.json at the repo root (kept there, not
  # here, so `just update-pins` can refresh all of them without touching
  # nix code). See scripts/update-pins.sh.
  pins = builtins.fromJSON (builtins.readFile ../../../pins.json);
  pinnedSkills = lib.mapAttrs (_: pkgs.fetchFromGitHub) pins;

  # Enforces the "never git, always jj" rule from global-claude.md as a hard
  # PreToolUse gate rather than prose. Reads the Bash tool-call JSON on stdin
  # and exits 2 (blocking, message fed back to Claude) on any direct `git`
  # invocation — while allowing `jj git ...`, `git-crypt`, `gh`, `lazygit`, and
  # git as a substring of other words. Wired into ~/.claude/settings.json by the
  # claudeGitHook activation below.
  blockGitHook = pkgs.writeShellApplication {
    name = "claude-block-git";
    runtimeInputs = with pkgs; [ jq gnugrep coreutils ];
    # The jq filter and grep pattern intentionally live in single quotes.
    excludeShellChecks = [ "SC2016" ];
    text = builtins.readFile ./hooks/block-git.sh;
  };

  # Idempotently merges the blockGitHook above into ~/.claude/settings.json.
  # Run from the claudeGitHook activation below; takes the hook command path as
  # its one argument. See ./hooks/register-git-hook.sh for the why.
  registerGitHook = pkgs.writeShellApplication {
    name = "claude-register-git-hook";
    runtimeInputs = with pkgs; [ jq coreutils ];
    # The jq filter intentionally lives in single quotes.
    excludeShellChecks = [ "SC2016" ];
    text = builtins.readFile ./hooks/register-git-hook.sh;
  };
in
{
  home.file = {
    # Computer-wide Claude Code memory: the shared jj/beads workflow processes,
    # applied across every project. Project-level CLAUDE.md files supplement it.
    ".claude/CLAUDE.md".source = ./global-claude.md;
    ".claude/skills/typst-author".source = pinnedSkills.typst-author-skill;
    ".claude/skills/rheo-author".source = pinnedSkills.rheo-author-skill;
    ".claude/skills/agentic-jujutsu".source = "${pinnedSkills.agentic-jujutsu-skill}/packages/agentic-jujutsu";
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

  # Register the git-blocking PreToolUse hook in ~/.claude/settings.json on every
  # rebuild. See ./hooks/register-git-hook.sh for why this is a mutable jq merge
  # rather than a home.file symlink.
  home.activation.claudeGitHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${registerGitHook}/bin/claude-register-git-hook "${blockGitHook}/bin/claude-block-git"
  '';

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
      set -x ANTHROPIC_MODEL glm-4.7
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
