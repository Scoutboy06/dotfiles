#!/usr/bin/env bash

# toggle-idle.sh - Toggle hypridle on/off
#
# Used by waybar idle-indicator on-click.
# Sends RTMIN+9 signal to waybar to refresh the indicator.

set -euo pipefail

if pgrep -x hypridle >/dev/null 2>&1; then
  # hypridle is running, stop it
  pkill -x hypridle
else
  # hypridle is not running, start it
  if command -v uwsm-app >/dev/null 2>&1; then
    uwsm-app -- hypridle >/dev/null 2>&1 &
  else
    hypridle >/dev/null 2>&1 &
  fi
fi

# Refresh waybar indicator
sleep 0.1
pkill -RTMIN+9 waybar 2>/dev/null || true
