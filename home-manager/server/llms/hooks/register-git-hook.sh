# claude-register-git-hook — wires the git-blocking PreToolUse hook into
# ~/.claude/settings.json. Usage: claude-register-git-hook <hook-command-path>
#
# A jq merge (not a home.file symlink) because Claude Code writes settings.json
# at runtime (theme, plugin state, statusline), so it must stay mutable. The
# merge is idempotent: it drops any prior block-git group before re-adding ours
# (pointing at the current store path) and preserves all other settings.
#
# Body only: pkgs.writeShellApplication supplies the shebang, `set -euo pipefail`,
# and jq/coreutils on PATH (see ../default.nix).

hook="$1"
settings="$HOME/.claude/settings.json"

if [ ! -e "$settings" ]; then
  mkdir -p "$(dirname "$settings")"
  echo '{}' > "$settings"
fi

tmp="$(mktemp)"
if jq --arg hook "$hook" '
  .hooks = (.hooks // {})
  | .hooks.PreToolUse = (
      [ (.hooks.PreToolUse // [])[]
        | select(([.hooks[]? | .command? // empty] | any(test("block-git"))) | not) ]
      + [ { matcher: "Bash", hooks: [ { type: "command", command: $hook } ] } ]
    )
' "$settings" > "$tmp" 2>/dev/null; then
  mv "$tmp" "$settings"
else
  rm -f "$tmp"
  echo "claude-register-git-hook: could not update $settings (invalid JSON?), left unchanged" >&2
fi
