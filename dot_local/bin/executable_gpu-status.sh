#!/usr/bin/env bash
set -euo pipefail

# GPU status monitor for Waybar
# Outputs JSON with icon and CSS class based on utilization
# Usage: gpu-status.sh [warning_threshold] [critical_threshold]

WARNING_THRESHOLD="${1:-70}"
CRITICAL_THRESHOLD="${2:-90}"

if ! command -v nvidia-smi &>/dev/null; then
  printf '{"text":"󰢮","class":""}\n'
  exit 0
fi

read -r UTIL MEM_USED MEM_TOTAL TEMP < <(
  nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
    --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ' | tr ',' ' '
)

if [[ -z "$UTIL" || "$UTIL" == "[NotSupported]" ]]; then
  printf '{"text":"󰢮","class":"","tooltip":"GPU: unavailable"}\n'
  exit 0
fi

CLASS=""
if (( UTIL >= CRITICAL_THRESHOLD )); then
  CLASS="critical"
elif (( UTIL >= WARNING_THRESHOLD )); then
  CLASS="warning"
fi

printf '{"text":"󰢮","class":"%s","tooltip":"GPU: %s%% | VRAM: %s/%s MB | Temp: %s°C"}\n' \
  "$CLASS" "$UTIL" "$MEM_USED" "$MEM_TOTAL" "$TEMP"
