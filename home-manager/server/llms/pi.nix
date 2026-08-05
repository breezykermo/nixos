{
  pkgs,
  lib,
  inputs,
  llmShared,
  theme,
  ...
}:
# Pi package, settings, models, skills, and theme.
let
  inherit (llmShared) globalMemory pinnedSkills;
  mix = theme.themeLib.mix;

  # Managed defaults; runtime-only settings remain mutable.
  piSettings = {
    theme = "system";
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-8";
    defaultThinkingLevel = "medium";
    # Startup-managed packages.
    packages =
      [
        "npm:pi-web-access"
        # "npm:@benvargas/pi-claude-code-use" # Claude Code OAuth compatibility.
        "/home/lox/code/_konrad/falconry" # Workflow extensions and skills.
      ];
  };

  # Local Ollama models.
  piModels = {
    providers.ollama = {
      baseUrl = "http://localhost:11434/v1";
      api = "openai-completions";
      apiKey = "ollama";

      compat = {
        supportsStore = false;
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
        supportsStrictMode = false;
        maxTokensField = "max_tokens";
      };

      models = [
        {
          id = "qwen3-coder:30b";
          name = "Qwen3 Coder 30B (Local)";
          input = [ "text" ];
          contextWindow = 262144;
          maxTokens = 32768;
        }
        {
          id = "qwen3.6:35b";
          name = "Qwen3.6 35B (Local)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 262144;
          maxTokens = 32768;
        }
        {
          id = "gpt-oss:120b";
          name = "GPT-OSS 120B (Local)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 131072;
          maxTokens = 32768;
        }
        {
          id = "MichelRosselli/GLM-4.5-Air:Q5_K_M";
          name = "GLM-4.5 Air (Local)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 131072;
          maxTokens = 32768;
        }
        {
          id = "deepseek-r1:latest";
          name = "DeepSeek R1 (Local)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 131072;
          maxTokens = 32768;
        }
      ];
    };
  };
  piModelsFile = pkgs.writeText "pi-models.json" (builtins.toJSON piModels);

  # Palette-driven theme.
  piTheme = {
    name = "system";
    colors = {
      # Core UI.
      accent = theme.colors.aqua;
      border = theme.colors.blue;
      borderAccent = theme.colors.aqua;
      borderMuted = theme.colors.bg3;
      success = theme.colors.green;
      error = theme.colors.red;
      warning = theme.colors.yellow;
      muted = theme.colors.fg3;
      dim = theme.colors.fg4;
      text = theme.foreground;
      thinkingText = theme.colors.fg3;

      # Messages.
      selectedBg = theme.colors.bg2;
      userMessageBg = theme.colors.bg1;
      userMessageText = theme.foreground;
      customMessageBg = mix theme.colors.purple theme.background 0.15;
      customMessageText = theme.foreground;
      customMessageLabel = theme.colors.purple;
      toolPendingBg = theme.colors.bg1;
      toolSuccessBg = mix theme.colors.green theme.background 0.12;
      toolErrorBg = mix theme.colors.red theme.background 0.12;
      toolTitle = theme.foreground;
      toolOutput = theme.colors.fg3;

      # Markdown rendering.
      mdHeading = theme.colors.yellow;
      mdLink = theme.colors.blue;
      mdLinkUrl = theme.colors.fg4;
      mdCode = theme.colors.aqua;
      mdCodeBlock = theme.colors.fg1;
      mdCodeBlockBorder = theme.colors.bg3;
      mdQuote = theme.colors.fg3;
      mdQuoteBorder = theme.colors.bg4;
      mdHr = theme.colors.bg3;
      mdListBullet = theme.colors.aqua;

      # Diffs.
      toolDiffAdded = theme.colors.green;
      toolDiffRemoved = theme.colors.red;
      toolDiffContext = theme.colors.fg3;

      # Syntax highlighting in code blocks.
      syntaxComment = theme.colors.fg4;
      syntaxKeyword = theme.colors.purple;
      syntaxFunction = theme.colors.blue;
      syntaxVariable = theme.colors.fg1;
      syntaxString = theme.colors.green;
      syntaxNumber = theme.colors.orange;
      syntaxType = theme.colors.aqua;
      syntaxOperator = theme.colors.bright_aqua;
      syntaxPunctuation = theme.colors.fg2;

      # Thinking levels.
      thinkingOff = theme.colors.bg3;
      thinkingMinimal = theme.colors.fg4;
      thinkingLow = theme.colors.blue;
      thinkingMedium = theme.colors.bright_blue;
      thinkingHigh = theme.colors.purple;
      thinkingXhigh = theme.colors.bright_purple;
      thinkingMax = theme.colors.bright_red;

      bashMode = theme.colors.bright_orange;
    };
    # HTML export.
    export = {
      pageBg = theme.background;
      cardBg = theme.colors.bg1;
      infoBg = mix theme.colors.yellow theme.background 0.15;
    };
  };
  piThemeFile = pkgs.writeText "system.json" (builtins.toJSON piTheme);

in {
  imports = [inputs.pi.homeModules.default];

  programs.pi.coding-agent = {
    enable = true;
    settings = piSettings;
  };

  home.file = {
    ".pi/agent/AGENTS.md".text = globalMemory;
    ".pi/agent/skills/typst-author".source = pinnedSkills.typst-author-skill;
    ".pi/agent/skills/rheo-author".source = pinnedSkills.rheo-author-skill;
    ".pi/agent/skills/agentic-jujutsu".source = "${pinnedSkills.agentic-jujutsu-skill}/packages/agentic-jujutsu";
    ".pi/agent/skills/bonsai-author".source = ./skills/bonsai-author;
    ".pi/agent/themes/system.json".source = piThemeFile;
    ".pi/agent/models.json".source = piModelsFile;
  };
}
