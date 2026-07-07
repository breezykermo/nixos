# claude-block-git — PreToolUse (Bash) hook.
#
# Enforces the "never git, always jj" rule from global-claude.md: reads the Bash
# tool-call JSON on stdin and exits 2 (blocking, message fed back to Claude) on
# any direct `git` invocation, while allowing `jj git ...`, `git-crypt`, `gh`,
# `lazygit`, and git as a substring of other words.
#
# This file is the body only: pkgs.writeShellApplication supplies the shebang
# and `set -euo pipefail`, and puts jq/grep on PATH (see ../default.nix).

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Match `git` invoked as a command: at line start or after a shell operator
# (optionally behind sudo/command/xargs/time/env), followed by whitespace or end
# — so `git-crypt` and `lazygit` don't match. grep is line-oriented, so `^` also
# catches git on its own line in a multi-line script.
if printf '%s' "$cmd" | grep -Eq '(^|[;&|(]|&&|\|\|)[[:space:]]*((sudo|command|xargs|time|env)[[:space:]]+)*git([[:space:]]|$)'; then
  echo "Blocked: this machine uses jj, never git (see ~/.claude/CLAUDE.md). Use jj equivalents: jj status/diff/log/show/file show, and jj git fetch for syncing. If you genuinely need raw git, ask the user to run it themselves." >&2
  exit 2
fi
exit 0
