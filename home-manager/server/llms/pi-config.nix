{
  pkgs,
  lib,
  pellucid,
  ...
}:
# Declarative pi (pi.dev) config, kept standalone from default.nix for
# readability/review. Imported by ./default.nix's `imports`.
#
# Split by how pi treats each path:
#   - READ-ONLY resources (extensions/skills/prompts/themes, models.json): pi
#     only reads them, so they are home.file symlinks into the nix store (same
#     pattern as the pinned Claude skills in default.nix). Edit them in
#     ./pi/<dir> (or the piModels attrset below) here and rebuild — NOT in
#     ~/.pi/agent (that path is a read-only store symlink).
#   - READ-WRITE settings.json: pi persists /settings, /model, theme, and
#     changelog dismissal to it at runtime, so it must stay a mutable real file.
#     Managed defaults are jq-merged in on activation (mirrors the claudeGitHook
#     precedent in default.nix), not symlinked.
#
# NOT managed here (pure runtime state / secrets, stays machine-local in
# ~/.pi/agent): auth.json, models-store.json, sessions/.
let
  # Nix-managed pi defaults — single source of truth. Merged into the mutable
  # settings.json; these keys win, pi's runtime-only keys are preserved.
  piSettings = {
    theme = "dark";
    defaultProvider = "ollama";
    defaultModel = "qwen3.6:35b";
    defaultThinkingLevel = "medium";
    # Packages pi auto-installs on startup if missing. See docs/packages.md;
    # entries here mirror what `pi install <spec>` would write. Sources land
    # under ~/.pi/agent/{npm,git}/ (runtime state, machine-local, NOT managed).
    #
    # Rejected during the 2026-07-31 audit and deliberately absent:
    #   - rpiv-todo, pi-beads-extension: duplicate/misname the br/jj/beads
    #     workflow that global-agents.md pins as the source of truth. A
    #     first-party replacement is tracked as beads issue nixos-0eu.
    #   - pi-lens: auto-installs ~25 external linter/LSP binaries into
    #     ~/.pi-lens/{bin,tools}/ via npx/pip/GitHub-release curls, a
    #     direct violation of the NixOS "everything declarative" rule and
    #     redundant with the per-project devShell toolchains.
    #   - context-mode: runtime-installs better-sqlite3 via ambient npm,
    #     ships ~1.5 MB of minified bundles, Elastic-2.0-licensed, and its
    #     before-agent hook mutates systemPrompt in a way that collides
    #     with ponytail's prefix-cache preservation. A first-party
    #     context-preservation extension is tracked as beads issue
    #     nixos-wfp (see the description there for the workarounds required).
    #
    # @dietrichgebert/ponytail is gated on the `pellucid` toggle in
    # ./default.nix: the two prose regimes are mutually exclusive (see the
    # comment there), so pellucid=true drops the package and pellucid=false
    # (this machine's default) installs it.
    packages =
      [
        "npm:pi-web-access" # https://pi.dev/packages/pi-web-access
        "git:github.com/breezykermo/pi-caveman" # https://github.com/breezykermo/pi-caveman
      ]
      ++ lib.optionals (!pellucid) [
        "npm:@dietrichgebert/ponytail" # https://pi.dev/packages/@dietrichgebert/ponytail
      ];
  };
  piSettingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON piSettings);

  # Nix-managed custom model providers (~/.pi/agent/models.json). pi only READS
  # this file (reloaded each time /model opens), so it fits the read-only
  # home.file symlink pattern. Local Ollama models live here; edit and rebuild.
  #
  # apiKey "ollama" is a placeholder Ollama ignores, but pi still requires a
  # value before models appear in /model. compat.supportsDeveloperRole/
  # supportsReasoningEffort=false suit Ollama's OpenAI-compatible server.
  piModels = {
    providers.ollama = {
      baseUrl = "http://localhost:11434/v1";
      api = "openai-completions";
      apiKey = "ollama";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
      };
      models = [
        {
          id = "qwen3-coder:30b";
          name = "Qwen3 Coder 30B (Local)";
          input = ["text"];
          contextWindow = 262144;
          maxTokens = 32768;
        }
        {
          id = "qwen3.6:35b";
          name = "Qwen3.6 35B (Local)";
          reasoning = true;
          input = ["text"];
          contextWindow = 262144;
          maxTokens = 32768;
        }
        {
          id = "gpt-oss:120b";
          name = "GPT-OSS 120B (Local)";
          reasoning = true;
          input = ["text"];
          contextWindow = 131072;
          maxTokens = 32768;
        }
        {
          id = "MichelRosselli/GLM-4.5-Air:Q5_K_M";
          name = "GLM-4.5 Air (Local)";
          reasoning = true;
          input = ["text"];
          contextWindow = 131072;
          maxTokens = 32768;
        }
        {
          id = "deepseek-r1:latest";
          name = "DeepSeek R1 (Local)";
          reasoning = true;
          input = ["text"];
          contextWindow = 131072;
          maxTokens = 32768;
        }
      ];
    };
  };
  piModelsFile = pkgs.writeText "pi-models.json" (builtins.toJSON piModels);

  # Idempotently merges piSettingsFile into ~/.pi/agent/settings.json.
  mergePiSettings = pkgs.writeShellApplication {
    name = "pi-merge-settings";
    runtimeInputs = with pkgs; [jq coreutils];
    # The jq filter intentionally lives in single quotes.
    excludeShellChecks = ["SC2016"];
    text = builtins.readFile ./hooks/merge-pi-settings.sh;
  };


in {
  home.file = {
    ".pi/agent/prompts".source = ./pi/prompts;
    ".pi/agent/extensions".source = ./pi/extensions;
    ".pi/agent/themes".source = ./pi/themes;
    ".pi/agent/models.json".source = piModelsFile;
  };

  home.activation.piSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${mergePiSettings}/bin/pi-merge-settings "${piSettingsFile}"
  '';
}
