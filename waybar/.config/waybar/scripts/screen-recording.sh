#!/usr/bin/env bash

# screen-recording.sh - Waybar indicator for screen recording status
#
# Output: JSON for waybar custom module
# Signal: RTMIN+8 (pkill -RTMIN+8 waybar to refresh)
#
# Shows an icon when screen recording is active (wf-recorder or wl-screenrec).

set -euo pipefail

# Check if wf-recorder or wl-screenrec is running
if pgrep -x wf-recorder >/dev/null 2>&1 || pgrep -x wl-screenrec >/dev/null 2>&1; then
  # Recording in progress - show red indicator
  printf '{"text": "󰻃", "tooltip": "Screen recording in progress", "class": "recording-active"}\n'
else
  # Not recording - show nothing
  printf '{"text": "", "tooltip": "", "class": "recording-inactive"}\n'
fi
