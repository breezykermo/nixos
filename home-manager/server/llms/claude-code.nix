{
  config,
  pkgs,
  lib,
  inputs,
  system,
  llmShared,
  theme,
  ...
}: let
  inherit (llmShared) falconryRepo globalMemory pinnedSkills;
  mix = theme.themeLib.mix;

  falconrySkillLinks = lib.listToAttrs (map (name: {
    name = ".claude/skills/${name}";
    value.source = config.lib.file.mkOutOfStoreSymlink "${falconryRepo}/skills/${name}";
  }) [
    "falconry-workflow"
    "falconry-hack"
    "falconry-slip"
    "jj-workspaces"
    "beads-plan-mode"
    "nixos-machine"
    "bead-quality"
  ]);

  # Palette-driven custom theme.
  claudeTheme = {
    name = "System (${theme.fullName})";
    base = "dark";
    overrides = {
      # Text and accents.
      claude = theme.colors.aqua;
      claudeShimmer = mix theme.colors.aqua theme.foreground 0.45;
      text = theme.foreground;
      inverseText = theme.background;
      inactive = theme.colors.fg4;
      inactiveShimmer = theme.colors.fg3;
      subtle = theme.colors.bg4;
      suggestion = theme.colors.blue;
      permission = theme.colors.purple;
      permissionShimmer = theme.colors.bright_purple;
      remember = theme.colors.orange;

      # Status.
      success = theme.colors.green;
      error = theme.colors.red;
      warning = theme.colors.yellow;
      warningShimmer = theme.colors.bright_yellow;
      merged = theme.colors.purple;

      # Input borders.
      promptBorder = theme.colors.blue;
      promptBorderShimmer = theme.colors.bright_blue;
      planMode = theme.colors.bright_blue;
      autoAccept = theme.colors.bright_green;
      bashBorder = theme.colors.bright_orange;
      ide = theme.colors.blue;
      fastMode = theme.colors.bright_yellow;
      fastModeShimmer = theme.colors.yellow;

      # Diffs.
      diffAdded = mix theme.colors.green theme.background 0.25;
      diffRemoved = mix theme.colors.red theme.background 0.25;
      diffAddedDimmed = mix theme.colors.green theme.background 0.12;
      diffRemovedDimmed = mix theme.colors.red theme.background 0.12;
      diffAddedWord = mix theme.colors.green theme.background 0.45;
      diffRemovedWord = mix theme.colors.red theme.background 0.45;

      # Fullscreen backgrounds.
      userMessageBackground = theme.colors.bg1;
      userMessageBackgroundHover = theme.colors.bg2;
      bashMessageBackgroundColor = mix theme.colors.orange theme.background 0.15;
      memoryBackgroundColor = mix theme.colors.purple theme.background 0.15;
      selectionBg = theme.colors.bg2;

      # Usage and transcript labels.
      rate_limit_fill = theme.colors.aqua;
      rate_limit_empty = theme.colors.bg3;
      briefLabelYou = theme.colors.blue;
      briefLabelClaude = theme.colors.aqua;

      # Subagents.
      red_FOR_SUBAGENTS_ONLY = theme.colors.red;
      blue_FOR_SUBAGENTS_ONLY = theme.colors.blue;
      green_FOR_SUBAGENTS_ONLY = theme.colors.green;
      yellow_FOR_SUBAGENTS_ONLY = theme.colors.yellow;
      purple_FOR_SUBAGENTS_ONLY = theme.colors.purple;
      orange_FOR_SUBAGENTS_ONLY = theme.colors.orange;
      pink_FOR_SUBAGENTS_ONLY = theme.colors.bright_red;
      cyan_FOR_SUBAGENTS_ONLY = theme.colors.aqua;
    };
  };
  claudeThemeFile = pkgs.writeText "claude-theme-system.json" (builtins.toJSON claudeTheme);

in {
  home.file = {
    # Global memory and skills.
    ".claude/CLAUDE.md".text = globalMemory;
    ".claude/themes/system.json".source = claudeThemeFile;
    ".claude/skills/typst-author".source = pinnedSkills.typst-author-skill;
    ".claude/skills/rheo-author".source = pinnedSkills.rheo-author-skill;
    ".claude/skills/agentic-jujutsu".source = "${pinnedSkills.agentic-jujutsu-skill}/packages/agentic-jujutsu";
    ".claude/skills/bonsai-author".source = ./skills/bonsai-author;

  }
  // falconrySkillLinks;

  home.shellAliases = {
    ccb = "claudebox --allow-ssh-agent";
  };

  programs.fish.functions = {
    # Claude against z.ai's Anthropic-compatible endpoint.
    glm = ''
      set -x ANTHROPIC_BASE_URL https://api.z.ai/api/anthropic
      set -x ANTHROPIC_AUTH_TOKEN (pass show ai/zai)
      set -x ANTHROPIC_MODEL glm-4.7
      command claude $argv
    '';
  };

  home.packages = [
    inputs.llm-agents.packages.${system}.claude-code
    inputs.llm-agents.packages.${system}.claudebox
  ];

  home.sessionVariables = {
    DISABLE_TELEMETRY = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
  };
}
