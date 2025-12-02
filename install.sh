#!/usr/bin/env bash

#!/usr/bin/env bash

set -e

error() {
    printf "Error: %s\n" "$1" >&2
    exit 1
}

# Check for Stow
if ! command -v stow >/dev/null 2>&1; then
    error "GNU Stow is not installed. Please install it before running this script."
fi

# CLI argument
if [ $# -lt 1 ]; then
    error "Usage: ./install.sh <config>"
fi

CONFIG=$(printf "%s" "$1" | tr '[:upper:]' '[:lower:]')

# Hard-coded apps for each config
declare -A APP_DIRS

case "$CONFIG" in
    omarchy)
        APP_DIRS=(
            [waybar]="omarchy"
            [hypr]="omarchy"
            [OpenTabletDriver]=""
            # add more here
        )
        ;;
    *)
        error "Unknown configuration '$1'. Valid options: omarchy"
        ;;
esac

printf "Installing configuration: %s\n\n" "$CONFIG"

for app in "${!APP_DIRS[@]}"; do
    pkg="${APP_DIRS[$app]}"

    printf "→ Stowing %s/%s\n" "$app" "$pkg"

    if [ ! -d "$app/$pkg" ]; then
        error "Directory '$app/$pkg' does not exist"
    fi

    # Ensure target directory exists (important!)
    mkdir -p "$HOME/.config/$app"

    # Dynamically target ~/.config/<app>
    stow --dir="$app" --target="$HOME/.config/$app" -v "$pkg"
done

printf "\nDone.\n"

