#!/usr/bin/env bash

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/p/dotfiles}"
cd "$DOTFILES_DIR" || exit 1

STATUS=$(git status --porcelain)

if [ -n "$STATUS" ]; then
    notify-send --wait \
        "Dotfiles need attention" \
        "$(printf '%s' "$STATUS" | head -n 10)"
fi
