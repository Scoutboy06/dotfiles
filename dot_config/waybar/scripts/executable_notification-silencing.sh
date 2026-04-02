#!/usr/bin/env bash

# notification-silencing.sh - Waybar indicator for Do Not Disturb status
#
# Output: JSON for waybar custom module
# Signal: RTMIN+10 (pkill -RTMIN+10 waybar to refresh)
#
# Shows an icon when notifications are silenced (DND mode).
# Supports mako (makoctl) and dunst (dunstctl).

set -euo pipefail

# Check mako first (more common on Hyprland)
if command -v makoctl >/dev/null 2>&1; then
  mode=$(makoctl mode 2>/dev/null || echo "")
  if [[ "$mode" == *"do-not-disturb"* ]]; then
    printf '{"text": "󰂛", "tooltip": "Do Not Disturb enabled", "class": "dnd-enabled"}\n'
  else
    printf '{"text": "", "tooltip": "Notifications enabled", "class": "dnd-disabled"}\n'
  fi
  exit 0
fi

# Fall back to dunst
if command -v dunstctl >/dev/null 2>&1; then
  paused=$(dunstctl is-paused 2>/dev/null || echo "false")
  if [[ "$paused" == "true" ]]; then
    printf '{"text": "󰂛", "tooltip": "Do Not Disturb enabled", "class": "dnd-enabled"}\n'
  else
    printf '{"text": "", "tooltip": "Notifications enabled", "class": "dnd-disabled"}\n'
  fi
  exit 0
fi

# No supported notification daemon found
printf '{"text": "", "tooltip": "No notification daemon found", "class": "dnd-unknown"}\n'
