# pi-merge-settings — merges the nix-managed pi defaults into the mutable
# ~/.pi/agent/settings.json. Usage: pi-merge-settings <managed-json-path>
#
# A jq merge (not a home.file symlink) because pi writes settings.json at
# runtime (lastChangelogVersion, /settings, /model, theme), so the file must
# stay mutable. Managed keys win; pi's own runtime-only keys are preserved.
# Idempotent — safe to run on every rebuild.
#
# Body only: pkgs.writeShellApplication supplies the shebang, `set -euo
# pipefail`, and jq/coreutils on PATH (see ../pi-config.nix).

managed="$1"
settings="$HOME/.pi/agent/settings.json"

if [ ! -e "$settings" ]; then
  mkdir -p "$(dirname "$settings")"
  echo '{}' > "$settings"
fi

tmp="$(mktemp)"
if jq --slurpfile managed "$managed" '. * $managed[0]' "$settings" > "$tmp" 2>/dev/null; then
  mv "$tmp" "$settings"
else
  rm -f "$tmp"
  echo "pi-merge-settings: could not update $settings (invalid JSON?), left unchanged" >&2
fi
