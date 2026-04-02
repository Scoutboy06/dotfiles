#!/bin/bash
# Ensure common XDG user directories exist

set -euo pipefail

dirs=(
    "$HOME/Desktop"
    "$HOME/Documents"
    "$HOME/Downloads"
    "$HOME/Music"
    "$HOME/Pictures"
    "$HOME/Public"
    "$HOME/Templates"
    "$HOME/Videos"
    "$HOME/Projects"
)

for dir in "${dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo "Created $dir"
    fi
done
