#!/usr/bin/env bash

# toggle-screen-recording.sh - Toggle screen recording with wf-recorder
#
# Used by waybar screenrecording-indicator on-click.
# Sends RTMIN+8 signal to waybar to refresh the indicator.

set -euo pipefail

RECORDINGS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"

if pgrep -x wf-recorder >/dev/null 2>&1; then
  # Stop recording
  pkill -INT wf-recorder
  sleep 0.2
  pkill -RTMIN+8 waybar 2>/dev/null || true
  notify-send "Recording stopped" "Saved to $RECORDINGS_DIR" 2>/dev/null || true
elif pgrep -x wl-screenrec >/dev/null 2>&1; then
  # Stop wl-screenrec if that's what's running
  pkill -INT wl-screenrec
  sleep 0.2
  pkill -RTMIN+8 waybar 2>/dev/null || true
  notify-send "Recording stopped" "Saved to $RECORDINGS_DIR" 2>/dev/null || true
else
  # Start recording
  mkdir -p "$RECORDINGS_DIR"
  timestamp=$(date +%Y-%m-%d_%H-%M-%S)
  output="$RECORDINGS_DIR/recording_$timestamp.mp4"

  if command -v wf-recorder >/dev/null 2>&1; then
    wf-recorder -f "$output" >/dev/null 2>&1 &
    sleep 0.3
    pkill -RTMIN+8 waybar 2>/dev/null || true
    notify-send "Recording started" "Output: $output" 2>/dev/null || true
  elif command -v wl-screenrec >/dev/null 2>&1; then
    wl-screenrec -f "$output" >/dev/null 2>&1 &
    sleep 0.3
    pkill -RTMIN+8 waybar 2>/dev/null || true
    notify-send "Recording started" "Output: $output" 2>/dev/null || true
  else
    notify-send "No screen recorder" "Install wf-recorder" 2>/dev/null || true
  fi
fi
