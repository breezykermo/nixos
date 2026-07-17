# jjj (jujutsu jump) — fzf-driven revset picker, after https://oppi.li/posts/jjj/.
#
# Behaves exactly like `jj`, except the revision is chosen interactively in fzf
# and spliced in as `-r <rev>`; every other arg is passed straight through.
# Uses builtin_log_oneline so each change is one line whose first 7+ char field
# is the change-id (what awk extracts).
#
# This file is the body only: pkgs.writeShellApplication supplies the shebang
# and `set -euo pipefail`, and puts jj/fzf/awk on PATH (see ./default.nix).

cmd="${1:-show}"
shift || true

selected=$(
  jj log -r 'all()' --color=always -T builtin_log_oneline \
    | fzf \
        --ansi \
        --cycle \
        --min-height=15 \
        --prompt "jj $cmd> " \
        --preview 'echo {} | awk "{for(i=1;i<=NF;i++) if(length(\$i)>=7){print \$i; exit}}" | xargs jj show --color=always' \
        --preview-window=right:60%
) || exit 0

rev=$(echo "$selected" | awk '{for(i=1;i<=NF;i++) if(length($i)>=7){print $i; exit}}')
[ -n "$rev" ] || exit 0

jj "$cmd" -r "$rev" "$@"
