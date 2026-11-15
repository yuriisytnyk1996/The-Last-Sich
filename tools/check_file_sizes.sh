#!/usr/bin/env bash
# Checks GDScript file sizes against the limits in docs/guide/code-organization.md.
#   > 200 lines: warning (consider splitting)
#   > 300 lines: error (must split)
# Usage: tools/check_file_sizes.sh   (run from the project root)

set -euo pipefail
cd "$(dirname "$0")/.."

WARN=200
MAX=300
status=0

while IFS= read -r file; do
	lines=$(wc -l < "$file" | tr -d ' ')
	if (( lines > MAX )); then
		echo "ERROR  $lines lines  $file (limit $MAX, must split)"
		status=1
	elif (( lines > WARN )); then
		echo "WARN   $lines lines  $file (over $WARN, consider splitting)"
	fi
done < <(find . -name '*.gd' -not -path './docs/*' -not -path './.godot/*' -not -path './addons/*')

if (( status == 0 )); then
	echo "File sizes OK"
fi
exit $status
