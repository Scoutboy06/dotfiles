#!/bin/bash
# Set zsh as default shell if not already

set -euo pipefail

# Check the actual login shell from the passwd database, not $SHELL — the
# $SHELL env var reflects the current session and can read as zsh while the
# login shell is still bash, silently skipping the change on a run_once script.
current_shell="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$current_shell" != */zsh ]]; then
    if command -v zsh &>/dev/null; then
        echo "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
        echo "Shell changed to zsh. Please log out and back in for it to take effect."
    else
        echo "Warning: zsh not found, skipping shell change"
    fi
fi
