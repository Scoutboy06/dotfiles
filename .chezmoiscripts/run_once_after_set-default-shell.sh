#!/bin/bash
# Set zsh as default shell if not already

set -euo pipefail

if [[ "$SHELL" != */zsh ]]; then
    if command -v zsh &>/dev/null; then
        echo "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
        echo "Shell changed to zsh. Please log out and back in for it to take effect."
    else
        echo "Warning: zsh not found, skipping shell change"
    fi
fi
