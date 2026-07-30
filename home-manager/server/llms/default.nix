{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}: let
  abacus = pkgs.callPackage ./abacus.nix {};
  beads = pkgs.callPackage ./beads.nix {};
  pi = pkgs.callPackage ./pi.nix {};

  # Prose-style toggle. When true, ./pellucid.md is appended to the global Claude
  # memory file, so its rules apply to every piece of prose Claude writes (docs,
  # explanations, commit/PR bodies, bead descriptions, subagent prompts). Flip to
  # false to drop the rules without editing either markdown file.
  pellucid = true;

  globalClaudeMd =
    builtins.readFile ./global-agents.md
    + lib.optionalString pellucid ("\n---\n\n" + builtins.readFile ./pellucid.md);

  # Skill source pins live in pins.json at the repo root (kept there, not
  # here, so `just update-pins` can refresh all of them without touching
  # nix code). See scripts/update-pins.sh.
  pins = builtins.fromJSON (builtins.readFile ../../../pins.json);
  pinnedSkills = lib.mapAttrs (_: pkgs.fetchFromGitHub) pins;

  # Enforces the "never git, always jj" rule from global-agents.md as a hard
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
  imports = [./pi-config.nix];

  home.file = {
    # Computer-wide Claude Code memory: the shared jj/beads workflow processes,
    # applied across every project. Project-level CLAUDE.md files supplement it.
    # Assembled (not symlinked) so the `pellucid` prose rules can be toggled in.
    ".claude/CLAUDE.md".text = globalClaudeMd;
    # Mirror to ~/.pi/agent/AGENTS.md so pi picks up the same global context.
    ".pi/agent/AGENTS.md".text = globalClaudeMd;
    ".claude/skills/typst-author".source = pinnedSkills.typst-author-skill;
    ".claude/skills/rheo-author".source = pinnedSkills.rheo-author-skill;
    ".claude/skills/agentic-jujutsu".source = "${pinnedSkills.agentic-jujutsu-skill}/packages/agentic-jujutsu";
    ".claude/skills/bonsai-author".source = ./skills/bonsai-author;

    # Mirror skills for pi (pi dev) alongside Claude Code so either agent
    # reads the same skill set without manual copy/paste.
    ".pi/agent/skills/typst-author".source = pinnedSkills.typst-author-skill;
    ".pi/agent/skills/rheo-author".source = pinnedSkills.rheo-author-skill;
    ".pi/agent/skills/agentic-jujutsu".source = "${pinnedSkills.agentic-jujutsu-skill}/packages/agentic-jujutsu";
    ".pi/agent/skills/bonsai-author".source = ./skills/bonsai-author;
  };

  # Register the git-blocking PreToolUse hook in ~/.claude/settings.json on every
  # rebuild. See ./hooks/register-git-hook.sh for why this is a mutable jq merge
  # rather than a home.file symlink.
  home.activation.claudeGitHook = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
  };

  home.packages = [
    beads
    abacus
    # pi coding agent (https://pi.dev) — binary is `pi`. Built from source out of
    # the upstream release tarball; see ./pi.nix for the version-bump recipe.
    pi
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
