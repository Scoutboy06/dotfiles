#!/usr/bin/env bash

# toggle-dnd.sh - Toggle Do Not Disturb mode
#
# Used by waybar notification-silencing-indicator on-click.
# Sends RTMIN+10 signal to waybar to refresh the indicator.
# Supports mako (makoctl) and dunst (dunstctl).

set -euo pipefail

# Try mako first
if command -v makoctl >/dev/null 2>&1; then
  mode=$(makoctl mode 2>/dev/null || echo "")
  if [[ "$mode" == *"do-not-disturb"* ]]; then
    makoctl mode -r do-not-disturb
  else
    makoctl mode -a do-not-disturb
  fi
  pkill -RTMIN+10 waybar 2>/dev/null || true
  exit 0
fi

# Fall back to dunst
if command -v dunstctl >/dev/null 2>&1; then
  dunstctl set-paused toggle
  pkill -RTMIN+10 waybar 2>/dev/null || true
  exit 0
fi

# No supported daemon
notify-send "No notification daemon" "Install mako or dunst" 2>/dev/null || true
