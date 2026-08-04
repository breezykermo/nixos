{
  config,
  pkgs,
  lib,
  inputs,
  system,
  theme,
  ...
}: let
  # `theme` is threaded in so abacus can be built with a generated theme source
  # file matching the active palette -- its themes are compiled in, not
  # configurable. See the header comment there.
  abacus = pkgs.callPackage ./abacus.nix {inherit theme;};
  beads = pkgs.callPackage ./beads.nix {};
  pi = pkgs.callPackage ./pi.nix {};

  mix = theme.themeLib.mix;

  # Prose-style toggle. Governs BOTH the appended global-memory rules AND the
  # pi package set (see ./pi-config.nix), since the two writing-style regimes are
  # mutually exclusive:
  #   pellucid = true  → append ./pellucid.md to the global Claude/pi memory
  #                      file (Bentley-Hart-style ornamented prose rules), and
  #                      OMIT the ponytail pi extension.
  #   pellucid = false → skip pellucid.md and INSTALL @dietrichgebert/ponytail,
  #                      which injects lazy-senior-dev minimalism instructions
  #                      into every turn. Pi's default posture on this machine.
  # The two disagree on ornament vs. terseness; running them together would give
  # the model contradictory nudges, so the toggle picks one.
  pellucid = false;

  # global-core.md holds the always-on rules and prohibitions, rendered to BOTH
  # harnesses. The long-running beads/jj PROCEDURES are NOT here — they live once,
  # as lazily-loaded skills in the falconry package, read by pi directly and by
  # Claude Code via the ~/.claude/skills symlinks (see default.nix home.file and
  # aus-zkt). So there is no separate procedures file to duplicate. See aus-doc-vn5.
  # The falconry repo, symlinked live into ~/.claude/skills below. Bound ONCE:
  # the path was previously repeated on seven lines and went stale (it said
  # /home/lox/code/falconry, a directory that no longer exists), which silently
  # dangled every skill symlink. See nixos-m1n.
  falconryRepo = "/home/lox/code/_konrad/falconry";
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

  globalMemory =
    builtins.readFile ./global-core.md
    + lib.optionalString pellucid ("\n---\n\n" + builtins.readFile ./pellucid.md);

  # Skill source pins live in pins.json at the repo root (kept there, not
  # here, so `just update-pins` can refresh all of them without touching
  # nix code). See scripts/update-pins.sh.
  pins = builtins.fromJSON (builtins.readFile ../../../pins.json);
  pinnedSkills = lib.mapAttrs (_: pkgs.fetchFromGitHub) pins;

  # Enforces the "never git, always jj" rule from global-core.md as a hard
  # PreToolUse gate rather than prose. Reads the Bash tool-call JSON on stdin
  # and exits 2 (blocking, message fed back to Claude) on any direct `git`
  # invocation — while allowing `jj git ...`, `git-crypt`, `gh`, `lazygit`, and
  # git as a substring of other words. Wired into ~/.claude/settings.json by the
  # claudeGitHook activation below.
  blockGitHook = pkgs.writeShellApplication {
    name = "claude-block-git";
    runtimeInputs = with pkgs; [jq gnugrep coreutils];
    # The jq filter and grep pattern intentionally live in single quotes.
    excludeShellChecks = ["SC2016"];
    text = builtins.readFile ./hooks/block-git.sh;
  };

  # brsave (the shell script that derived .beads/open.jsonl) was REMOVED: the
  # falconry pi extension now owns that derivation and refreshes open.jsonl
  # automatically after any br mutation inside a pi session (verified live
  # 2026-08-02). Keeping two implementations of the same export invited silent
  # drift. Accepted consequence: outside a pi session nothing refreshes the
  # export; a bare-shell `br close` leaves it stale until the next pi session's
  # session-start invariant check notices (visible, not silent). See aus-rmb-95j.

  # Claude Code custom theme, generated from the active palette in
  # themes/default.nix so the TUI matches Ghostty and Neovim instead of Claude's
  # built-in presets. Claude Code loads ~/.claude/themes/<slug>.json, where the
  # slug is the FILENAME; selecting it records `custom:<slug>` in settings.json
  # (docs: code.claude.com/docs/en/terminal-config#create-a-custom-theme,
  # requires Claude Code >= 2.1.118). Only listed tokens are overridden -- the
  # rest fall through to `base`, and unknown tokens / invalid colors are ignored
  # rather than fatal, so an upstream token rename degrades to the preset.
  #
  # Named `system` rather than `moonfly` for the same reason tuicr's theme is
  # (home-manager/server/editor/vcs/default.nix): it follows whatever palette
  # themes/default.nix has active, so switching themes needs no rename here.
  claudeTheme = {
    name = "System (${theme.fullName})";
    base = "dark";
    overrides = {
      # Text and accents. `subtle` is faint borders, `inactive` is hint text.
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

      # Input box border, one color per permission mode.
      promptBorder = theme.colors.blue;
      promptBorderShimmer = theme.colors.bright_blue;
      planMode = theme.colors.bright_blue;
      autoAccept = theme.colors.bright_green;
      bashBorder = theme.colors.bright_orange;
      ide = theme.colors.blue;
      fastMode = theme.colors.bright_yellow;
      fastModeShimmer = theme.colors.yellow;

      # Diffs. The `*Dimmed` pair is context near a change, so it gets a lighter
      # wash of the same hue; the word-level pair is the strongest. Same
      # palette-mixed washes delta and tuicr use, so a diff reads identically in
      # all three.
      diffAdded = mix theme.colors.green theme.background 0.25;
      diffRemoved = mix theme.colors.red theme.background 0.25;
      diffAddedDimmed = mix theme.colors.green theme.background 0.12;
      diffRemovedDimmed = mix theme.colors.red theme.background 0.12;
      diffAddedWord = mix theme.colors.green theme.background 0.45;
      diffRemovedWord = mix theme.colors.red theme.background 0.45;

      # Fullscreen rendering only (`/tui fullscreen`).
      userMessageBackground = theme.colors.bg1;
      userMessageBackgroundHover = theme.colors.bg2;
      bashMessageBackgroundColor = mix theme.colors.orange theme.background 0.15;
      memoryBackgroundColor = mix theme.colors.purple theme.background 0.15;
      selectionBg = theme.colors.bg2;

      # `/usage` meter and the You/Claude transcript labels.
      rate_limit_fill = theme.colors.aqua;
      rate_limit_empty = theme.colors.bg3;
      briefLabelYou = theme.colors.blue;
      briefLabelClaude = theme.colors.aqua;

      # The eight named colors a subagent/parallel task can be tagged with.
      # Moonfly has no pink, so crimson (its bright red) stands in.
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

  # Nix-managed Claude Code settings defaults. Kept minimal on purpose: the file
  # is read-write (Claude persists plugin state, statusline, model, theme), so
  # every key listed here WINS over an interactive change on the next rebuild.
  claudeSettings = {
    # Selects claudeThemeFile above. Must stay `custom:<filename-without-.json>`.
    theme = "custom:system";
  };
  claudeSettingsFile = pkgs.writeText "claude-settings.json" (builtins.toJSON claudeSettings);

  # Idempotently merges claudeSettingsFile into ~/.claude/settings.json.
  mergeClaudeSettings = pkgs.writeShellApplication {
    name = "claude-merge-settings";
    runtimeInputs = with pkgs; [jq coreutils];
    # The jq filter intentionally lives in single quotes.
    excludeShellChecks = ["SC2016"];
    text = builtins.readFile ./hooks/merge-claude-settings.sh;
  };

  # Idempotently merges the blockGitHook above into ~/.claude/settings.json.
  # Run from the claudeGitHook activation below; takes the hook command path as
  # its one argument. See ./hooks/register-git-hook.sh for the why.
  registerGitHook = pkgs.writeShellApplication {
    name = "claude-register-git-hook";
    runtimeInputs = with pkgs; [jq coreutils];
    # The jq filter intentionally lives in single quotes.
    excludeShellChecks = ["SC2016"];
    text = builtins.readFile ./hooks/register-git-hook.sh;
  };
in {
  # Declarative pi (pi.dev) config lives in its own module for readability.
  # `pellucid` is threaded in via _module.args below so pi-config.nix can gate
  # the ponytail package on the same toggle that gates ./pellucid.md.
  imports = [./pi-config.nix];
  _module.args.pellucid = pellucid;

  # falconrySkillLinks is merged in at the end: it supplies the seven
  # .claude/skills/<name> live symlinks (see the let block).
  home.file = {
    # Computer-wide Claude Code memory: the shared jj/beads workflow processes,
    # applied across every project. Project-level CLAUDE.md files supplement it.
    # Assembled (not symlinked) so the `pellucid` prose rules can be toggled in.
    ".claude/CLAUDE.md".text = globalMemory;
    # Mirror to ~/.pi/agent/AGENTS.md so pi picks up the same global context.
    ".pi/agent/AGENTS.md".text = globalMemory;
    # Palette-driven Claude Code theme (see claudeTheme above). Selected by the
    # `theme = "custom:system"` key merged into settings.json below. Claude Code
    # watches this directory and hot-reloads, but it only starts watching if the
    # directory existed at launch -- so the first rebuild that creates it needs
    # one Claude restart.
    ".claude/themes/system.json".source = claudeThemeFile;
    ".claude/skills/typst-author".source = pinnedSkills.typst-author-skill;
    ".claude/skills/rheo-author".source = pinnedSkills.rheo-author-skill;
    ".claude/skills/agentic-jujutsu".source = "${pinnedSkills.agentic-jujutsu-skill}/packages/agentic-jujutsu";
    ".claude/skills/bonsai-author".source = ./skills/bonsai-author;

    # falconry workflow skills, symlinked live (mkOutOfStoreSymlink) into
    # Claude Code so both harnesses share ONE source — editing a SKILL.md in the
    # falconry repo changes what Claude Code sees, no rebuild. This is what
    # lets the procedural prose live once in the package's skills/ rather than
    # being duplicated in global-core.md (closes the drift bug). pi reads these
    # directly from the loaded falconry package, so no pi mirror needed.
    # See aus-zkt / aus-doc-vn5. The seven entries come from falconrySkillLinks
    # in the let block above (one place holds the repo path).

    # Mirror skills for pi (pi dev) alongside Claude Code so either agent
    # reads the same skill set without manual copy/paste.
    ".pi/agent/skills/typst-author".source = pinnedSkills.typst-author-skill;
    ".pi/agent/skills/rheo-author".source = pinnedSkills.rheo-author-skill;
    ".pi/agent/skills/agentic-jujutsu".source = "${pinnedSkills.agentic-jujutsu-skill}/packages/agentic-jujutsu";
    ".pi/agent/skills/bonsai-author".source = ./skills/bonsai-author;
  }
  // falconrySkillLinks;

  # Register the git-blocking PreToolUse hook in ~/.claude/settings.json on every
  # rebuild. See ./hooks/register-git-hook.sh for why this is a mutable jq merge
  # rather than a home.file symlink.
  home.activation.claudeGitHook = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${registerGitHook}/bin/claude-register-git-hook "${blockGitHook}/bin/claude-block-git"
  '';

  # Merge the managed defaults (currently just the theme selection) into the same
  # mutable settings.json. Separate from the hook activation above because that
  # one rewrites a hook array in place, while this is a plain key merge.
  home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${mergeClaudeSettings}/bin/claude-merge-settings "${claudeSettingsFile}"
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
  };

  home.packages = [
    beads
    abacus
    # pi coding agent (https://pi.dev) — binary is `pi`. Built from source out of
    # the upstream release tarball; see ./pi.nix for the version-bump recipe.
    pi
    inputs.codex-nix.packages.${system}.codex
    inputs.llm-agents.packages.${system}.claude-code
    inputs.llm-agents.packages.${system}.claudebox
    # Qwen Coder CLI (https://coder.qwen.ai/) — binary is `qwen`. Built from source
    # out of my fork github.com/breezykermo/qwen-code, which carries the flake:
    # nixpkgs and llm-agents.nix both lag upstream, and the fork lets local patches
    # ship exactly as deployed. Bump with `just upp i=qwen-code`.
    inputs.qwen-code.packages.${system}.qwen-code
  ];

  home.sessionVariables = {
    # Claude code
    DISABLE_TELEMETRY = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
  };
}
