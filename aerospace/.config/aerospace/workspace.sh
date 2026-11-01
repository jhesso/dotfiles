#!/bin/bash
# Hyprland-style workspace switching:
# - Workspace already has windows (or is visible) -> go to it on whatever monitor it lives on
# - Pinned workspace (workspace-to-monitor-force-assignment) -> always its own monitor
# - Empty / new workspace -> open it on the monitor under the mouse cursor
PINNED=" 1 2 3 4 5 6 7 8 9 10 "   # keep in sync with aerospace.toml
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
ws="$1"

if [[ "$PINNED" == *" $ws "* ]] \
   || aerospace list-workspaces --monitor all --visible | grep -qx "$ws" \
   || aerospace list-windows --workspace "$ws" | grep -q .; then
  aerospace workspace "$ws"
else
  mon="$(aerospace list-monitors --mouse --format '%{monitor-id}')"
  aerospace focus-monitor "$mon"
  aerospace summon-workspace "$ws"
fi
