{
  pkgs,
  lib,
  ...
}:
# Declarative pi (pi.dev) config, kept standalone from default.nix for
# readability/review. Imported by ./default.nix's `imports`.
#
# Split by how pi treats each path:
#   - READ-ONLY resources (extensions/skills/prompts/themes): pi only reads
#     them, so they are home.file symlinks into the nix store (same pattern as
#     the pinned Claude skills in default.nix). Edit them in ./pi/<dir> here and
#     rebuild — NOT in ~/.pi/agent (that path is a read-only store symlink).
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
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-8";
    defaultThinkingLevel = "medium";
  };
  piSettingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON piSettings);

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
    ".pi/agent/skills".source = ./pi/skills;
    ".pi/agent/extensions".source = ./pi/extensions;
    ".pi/agent/themes".source = ./pi/themes;
  };

  home.activation.piSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${mergePiSettings}/bin/pi-merge-settings "${piSettingsFile}"
  '';
}
