#!/usr/bin/env bash
# Runs the single push-based `speak status --json --follow` for all bar
# instances (callers hold an flock) and mirrors every line into a state file
# that every per-screen widget instance watches. Written in place (no rename)
# so file watchers keep following the same inode.
state="${XDG_RUNTIME_DIR:-/tmp}/elias.speak.state.json"
speak status --json --follow | while IFS= read -r line; do
  printf '%s\n' "$line" > "$state"
  printf '%s\n' "$line"
done
printf '%s\n' '{"protocol":1,"state":"off","speed":1,"voice":"","queued":0,"current":""}' > "$state"
