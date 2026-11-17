#!/usr/bin/env bash
# Builds levels/map/map_catalog.tres from the room scenes (see tools/build_map_catalog.gd).
#   tools/map_catalog.sh           rebuild the catalog
#   tools/map_catalog.sh --check   exit 1 if it is out of date
# Godot is $GODOT, else the macOS app, else `godot` on PATH.

set -euo pipefail
cd "$(dirname "$0")/.."

godot="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
[[ -x "$godot" ]] || godot="godot"

args=()
[[ "${1:-}" == "--check" ]] && args=(-- --check)
exec "$godot" --headless --path . -s tools/build_map_catalog.gd ${args[@]+"${args[@]}"}
