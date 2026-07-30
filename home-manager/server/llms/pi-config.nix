{
  pkgs,
  lib,
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
