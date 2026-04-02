#!/usr/bin/env bash

# idle-indicator.sh - Waybar indicator for hypridle status
#
# Output: JSON for waybar custom module
# Signal: RTMIN+9 (pkill -RTMIN+9 waybar to refresh)
#
# Shows an icon when idle lock (hypridle) is disabled.

set -euo pipefail

# Check if hypridle is running
if pgrep -x hypridle >/dev/null 2>&1; then
  # Idle lock is enabled (hypridle running) - show nothing
  printf '{"text": "", "tooltip": "Idle lock enabled", "class": "idle-enabled"}\n'
else
  # Idle lock is disabled (hypridle not running) - show indicator
  printf '{"text": "󰒳", "tooltip": "Idle lock disabled", "class": "idle-disabled"}\n'
fi
