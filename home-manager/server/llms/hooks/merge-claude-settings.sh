# claude-merge-settings — merges the nix-managed Claude Code defaults into the
# mutable ~/.claude/settings.json. Usage: claude-merge-settings <managed-json-path>
#
# A jq merge (not a home.file symlink) because Claude Code writes settings.json
# at runtime (plugin state, statusline, model, theme), so the file must stay
# mutable. Managed keys win; Claude's own runtime-only keys are preserved. That
# means an interactive `/theme` change to a managed key is reset on the next
# rebuild — change the `claudeSettings` attrset in ../default.nix instead.
# Idempotent — safe to run on every rebuild.
#
# Body only: pkgs.writeShellApplication supplies the shebang, `set -euo
# pipefail`, and jq/coreutils on PATH (see ../default.nix).

managed="$1"
settings="$HOME/.claude/settings.json"

if [ ! -e "$settings" ]; then
  mkdir -p "$(dirname "$settings")"
  echo '{}' > "$settings"
fi

tmp="$(mktemp)"
if jq --slurpfile managed "$managed" '. * $managed[0]' "$settings" > "$tmp" 2>/dev/null; then
  mv "$tmp" "$settings"
else
  rm -f "$tmp"
  echo "claude-merge-settings: could not update $settings (invalid JSON?), left unchanged" >&2
fi
