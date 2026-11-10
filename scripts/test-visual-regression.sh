#!/usr/bin/env bash
# Deterministic contract test for visual-regression.sh.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tool="$root/scripts/visual-regression.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

command -v convert >/dev/null || { echo "ImageMagick is required." >&2; exit 2; }

convert -size 20x20 xc:'#f9f9f9' "$tmp/reference.png"
cp "$tmp/reference.png" "$tmp/identical.png"
"$tool" --reference "$tmp/reference.png" --actual "$tmp/identical.png" --output "$tmp/identical-diff.png" --threshold 0

convert "$tmp/reference.png" -fill '#000000' -draw 'point 0,0' "$tmp/changed.png"
if "$tool" --reference "$tmp/reference.png" --actual "$tmp/changed.png" --output "$tmp/changed-diff.png" --threshold 0; then
    echo "Expected a changed image to fail at zero tolerance." >&2
    exit 1
fi

echo "visual-regression contract tests passed"
