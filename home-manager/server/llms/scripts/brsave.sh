# brsave — write .beads/open.jsonl, the one part of the issue tracker a repo shares.
#
#   brsave            refresh the export
#   brsave --check    exit 1 if it is out of date, write nothing
#   brsave --import   rebuild a local db from the export (fresh clone)
#
# br keeps one JSONL for everything: .beads/issues.jsonl holds open, in-progress
# and closed beads alike, one JSON object per line, and br rewrites the whole file
# on each mutation. Ignore rules select paths and never lines, so sharing only the
# live work means deriving a second file — this one. Each repo's .gitignore tracks
# open.jsonl and ignores the rest of .beads/; brsave warns when those lines are
# missing rather than editing the file itself.
#
# Installed computer-wide by home-manager (home-manager/server/llms/default.nix)
# because the rule it implements is computer-wide. It operates on whatever repo the
# current directory sits in, so there is nothing to copy into a new project.

set -euo pipefail

usage() {
    cat <<'EOF'
brsave — export the open beads a repo shares (.beads/open.jsonl)

  brsave            refresh the export
  brsave --check    exit 1 if it is out of date, write nothing
  brsave --import   rebuild a local db from the export
EOF
}

mode="export"
case "${1:-}" in
"") ;;
--check) mode="check" ;;
--import) mode="import" ;;
-h | --help)
    usage
    exit 0
    ;;
*)
    echo "brsave: unknown argument '$1'" >&2
    usage >&2
    exit 2
    ;;
esac

# Repo root, jj first: this machine's repos are jj, some colocated with git and
# some not. In a jj workspace this resolves to that workspace's own root, which is
# what we want — the export is a tracked file, so each working copy has its own.
root=""
if command -v jj >/dev/null && root="$(jj workspace root 2>/dev/null)"; then
    :
elif command -v git >/dev/null && root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    :
else
    # No VCS answer — walk up looking for the tracker itself.
    root=""
    dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.beads" ]; then
            root="$dir"
            break
        fi
        dir="$(dirname "$dir")"
    done
fi

if [ -z "$root" ]; then
    echo "brsave: no repo root above $PWD" >&2
    exit 1
fi

BEADS="$root/.beads"
FULL="$BEADS/issues.jsonl"
OPEN="$BEADS/open.jsonl"

if [ ! -d "$BEADS" ]; then
    echo "brsave: no $BEADS — run 'br init --prefix <short>' in $root first" >&2
    exit 1
fi

# Statuses that count as live work. br's vocabulary is open, in_progress, blocked,
# deferred, draft, closed, tombstone and pinned; a bead in any state other than
# these two stays local, so parking something with `br defer` also parks it from
# the repo's point of view.
FILTER='select(.status == "open" or .status == "in_progress")'

if [ "$mode" = "import" ]; then
    # For a fresh clone, which arrives with open.jsonl and nothing else. br reads
    # issues.jsonl, so the export becomes the seed, and --rename-prefix fixes any
    # bead filed under another workspace's prefix. Dependencies pointing at closed
    # beads are dropped silently, which is harmless: a closed bead blocks nothing.
    if [ ! -f "$OPEN" ]; then
        echo "brsave: $OPEN does not exist" >&2
        exit 1
    fi
    if [ -s "$FULL" ]; then
        echo "brsave: $FULL is not empty; refusing to overwrite it" >&2
        exit 1
    fi
    cp "$OPEN" "$FULL"
    br sync --import-only --rename-prefix
    exit 0
fi

# Flush first, or we would filter a stale export. This is a no-op when nothing is
# dirty, and --force gets past the stale-DB guard when a bead was imported rather
# than created here.
br sync --flush-only --force >/dev/null

# Written via a temporary and renamed, so an interrupted run cannot leave a
# truncated export where a good one was. jq preserves both line order (br sorts
# issues.jsonl by id) and key order, so a bead nobody touched produces no diff.
temporary="$OPEN.partial"
jq -c "$FILTER" "$FULL" >"$temporary"

if [ "$mode" = "check" ]; then
    if [ -f "$OPEN" ] && cmp -s "$temporary" "$OPEN"; then
        rm -f "$temporary"
        echo "brsave: .beads/open.jsonl is up to date"
        exit 0
    fi
    rm -f "$temporary"
    echo "brsave: .beads/open.jsonl is out of date — run brsave" >&2
    exit 1
fi

mv "$temporary" "$OPEN"
echo "brsave: wrote $(wc -l <"$OPEN" | tr -d ' ') live bead(s) to .beads/open.jsonl"

# An export nothing tracks is an export nobody reads. The three lines are
# order-sensitive: a negation cannot re-enter a directory excluded as a directory,
# and ~/.config/git/ignore carries a `**/.beads/` rule from an old `bd init
# --stealth` that a repo .gitignore has to outrank. Warn, never edit — .gitignore
# is the repo's to write.
if ! grep -qF '!/.beads/open.jsonl' "$root/.gitignore" 2>/dev/null; then
    cat >&2 <<EOF

brsave: $root/.gitignore does not track the export. Add, in this order:

    !/.beads/
    /.beads/*
    !/.beads/open.jsonl

and remove any blanket '.beads/' line above them.
EOF
fi
