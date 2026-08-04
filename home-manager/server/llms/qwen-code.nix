{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}: let
  # Homework defaults for local Ollama models.
  qwenSystemDefaults = pkgs.writeText "qwen-code-system-defaults.json" (builtins.toJSON {
    general.enableAutoUpdate = false;
    privacy.usageStatisticsEnabled = false;
    telemetry = {
      enabled = false;
      logPrompts = false;
    };

    env.OLLAMA_API_KEY = "ollama";
    security.auth.selectedType = "openai";
    model.name = "qwen3.6:35b";

    modelProviders.openai = [
      {
        id = "qwen3.6:35b";
        name = "Qwen3.6 35B-A3B (local ollama)";
        description = "MoE coding/agentic model on the Strix Halo iGPU";
        envKey = "OLLAMA_API_KEY";
        baseUrl = "http://127.0.0.1:11434/v1";
        generationConfig = {
          timeout = 600000;
          maxRetries = 1;
          # Match OLLAMA_CONTEXT_LENGTH.
          contextWindowSize = 131072;
        };
      }
      {
        id = "qwen3-coder:30b";
        name = "Qwen3 Coder 30B (local ollama)";
        envKey = "OLLAMA_API_KEY";
        baseUrl = "http://127.0.0.1:11434/v1";
        generationConfig = {
          timeout = 600000;
          maxRetries = 1;
          contextWindowSize = 131072;
        };
      }
    ];
  });
in {
  home.packages = [inputs.qwen-code.packages.${system}.qwen-code];

  home.sessionVariables = lib.mkIf config.custom.homework {
    QWEN_CODE_SYSTEM_DEFAULTS_PATH = "${qwenSystemDefaults}";
  };
}
