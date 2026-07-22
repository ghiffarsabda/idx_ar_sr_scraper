#!/usr/bin/env bash
# clear.sh - Clears output files and resets progress for a fresh start.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Clearing previous run outputs..."

# Remove progress.json, result-log.json, last-result.json, urls_temp.sh
rm -f "$BASE_DIR/progress.json"
rm -f "$BASE_DIR/results/last-result.json"
rm -f "$BASE_DIR/results/result-log.json"
rm -f "$BASE_DIR/results/urls_temp.sh"
rm -f "$BASE_DIR"/.prompt_*.txt

# Reset download_reports.sh with header
echo "#!/usr/bin/env bash" > "$BASE_DIR/results/download_reports.sh"
chmod +x "$BASE_DIR/results/download_reports.sh"

# Ensure pdfs directory exists and is emptied
mkdir -p "$BASE_DIR/results/pdfs"
rm -rf "$BASE_DIR/results/pdfs"/*

echo "Outputs cleared. Ready for fresh start."
