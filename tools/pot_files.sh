#!/usr/bin/env bash
# Fills the POT generation file list in project.godot (see tools/update_pot_files.gd).
#   tools/pot_files.sh           update the list
#   tools/pot_files.sh --check   exit 1 if it is out of date
# Runs in the editor, which the text extractor needs. Godot is $GODOT, else
# the macOS app, else `godot` on PATH.

set -euo pipefail
cd "$(dirname "$0")/.."

godot="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
[[ -x "$godot" ]] || godot="godot"

args=()
[[ "${1:-}" == "--check" ]] && args=(-- --check)
exec "$godot" --headless --editor --path . -s tools/update_pot_files.gd ${args[@]+"${args[@]}"}
