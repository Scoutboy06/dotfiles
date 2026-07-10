#!/bin/bash
set -eu

# Register the pi config package (cloned to ~/p/pi via .chezmoiexternal.toml).
# pi may not be on PATH yet on a fresh machine (bun installs it earlier in
# this same apply run, before .zshrc adds ~/.bun/bin), so check there too.
if command -v pi >/dev/null 2>&1; then
    PI=pi
elif [ -x "$HOME/.bun/bin/pi" ]; then
    PI="$HOME/.bun/bin/pi"
else
    exit 0
fi

"$PI" install "$HOME/p/pi"
