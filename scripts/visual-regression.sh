#!/usr/bin/env bash
# Compare a captured Plasma screen to an approved Windows 11 reference.
# The script is intentionally desktop-agnostic so it can run locally and in CI.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: visual-regression.sh --reference FILE --actual FILE --output FILE [--threshold FRACTION] [--crop GEOMETRY]

The normalized RMSE score is 0 for identical images and 1 for maximum
pixel difference. Exit status is non-zero when the score exceeds threshold.
EOF
}

reference=""
actual=""
output=""
threshold="0.015"
crop=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reference) reference="$2"; shift 2 ;;
        --actual) actual="$2"; shift 2 ;;
        --output) output="$2"; shift 2 ;;
        --threshold) threshold="$2"; shift 2 ;;
        --crop) crop="$2"; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ -n "$reference" && -n "$actual" && -n "$output" ]] || { usage >&2; exit 2; }
[[ -f "$reference" && -f "$actual" ]] || { echo "Reference or capture missing." >&2; exit 2; }
command -v compare >/dev/null || { echo "ImageMagick 'compare' is required." >&2; exit 2; }
command -v identify >/dev/null || { echo "ImageMagick 'identify' is required." >&2; exit 2; }

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
ref_input="$reference"
actual_input="$actual"

if [[ -n "$crop" ]]; then
    command -v convert >/dev/null || { echo "ImageMagick 'convert' is required for --crop." >&2; exit 2; }
    convert "$reference" -crop "$crop" +repage "$workdir/reference.png"
    convert "$actual" -crop "$crop" +repage "$workdir/actual.png"
    ref_input="$workdir/reference.png"
    actual_input="$workdir/actual.png"
fi

ref_size="$(identify -format '%wx%h' "$ref_input")"
actual_size="$(identify -format '%wx%h' "$actual_input")"
[[ "$ref_size" == "$actual_size" ]] || { echo "Image sizes differ: reference=$ref_size actual=$actual_size" >&2; exit 2; }

metric_file="$workdir/metric.txt"
compare -metric RMSE "$ref_input" "$actual_input" "$output" 2>"$metric_file" || status=$?
status="${status:-0}"
metric="$(sed -n 's/.*(\([0-9.]*\)).*/\1/p' "$metric_file" | tail -1)"
[[ -n "$metric" ]] || { cat "$metric_file" >&2; exit "$status"; }

printf 'Visual RMSE: %s (threshold: %s)\n' "$metric" "$threshold"
awk -v metric="$metric" -v threshold="$threshold" 'BEGIN { exit !(metric <= threshold) }' || {
    echo "Visual regression exceeds threshold; diff written to $output" >&2
    exit 1
}
