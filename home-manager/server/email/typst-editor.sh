#!/usr/bin/env bash
# Wrapper script to edit aerc compose files with .typ extension
# This enables Typst syntax highlighting in the editor

set -euo pipefail

ORIGINAL="$1"
TYPST_FILE="${ORIGINAL}.typ"

# Copy to .typ extension for syntax highlighting
cp "$ORIGINAL" "$TYPST_FILE"

# Open in configured editor
${EDITOR:-nvim} "$TYPST_FILE"

# Copy back to original location
cp "$TYPST_FILE" "$ORIGINAL"
rm "$TYPST_FILE"
