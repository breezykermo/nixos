#!/usr/bin/env bash
# Wrapper script for converting Typst to HTML via stdin/stdout
# Used by aerc's multipart-converters

set -euo pipefail

# Create temporary files
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

INPUT_FILE="$TMPDIR/input.typ"
OUTPUT_FILE="$TMPDIR/output.html"

# Read stdin to temporary Typst file
cat > "$INPUT_FILE"

# Convert Typst to HTML using typst's experimental HTML export
typst compile --features html --format html "$INPUT_FILE" "$OUTPUT_FILE" 2>/dev/null

# Output HTML to stdout
cat "$OUTPUT_FILE"
