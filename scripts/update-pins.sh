#!/usr/bin/env bash
# Refreshes sha256 hashes in pins.json to match the current HEAD of each
# pinned repo's tracked ref (usually "main"). Run via `just up`, or `just
# update-pins` on its own. Requires network access.
set -euo pipefail

cd "$(dirname "$0")/.."

pins_file="pins.json"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

cp "$pins_file" "$tmp"

for name in $(jq -r 'keys[]' "$pins_file"); do
  owner=$(jq -r ".\"$name\".owner" "$pins_file")
  repo=$(jq -r ".\"$name\".repo" "$pins_file")
  rev=$(jq -r ".\"$name\".rev" "$pins_file")

  echo "Refreshing $name ($owner/$repo@$rev)..."
  result=$(nix run nixpkgs#nix-prefetch-github -- "$owner" "$repo" --rev "$rev")
  new_sha256=$(jq -r '.hash' <<<"$result")

  jq --arg name "$name" --arg sha256 "$new_sha256" \
    '.[$name].sha256 = $sha256' "$tmp" > "$tmp.next"
  mv "$tmp.next" "$tmp"
done

mv "$tmp" "$pins_file"
echo "pins.json updated."
