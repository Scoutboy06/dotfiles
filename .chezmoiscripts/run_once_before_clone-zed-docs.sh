#!/bin/bash
# Clone zed docs with sparse checkout to ~/.docs/zed (docs/src only).
# Runs once per machine (tracked by content hash). Skip if already cloned.
set -euo pipefail

ZED_DOCS_DIR="$HOME/.docs/zed"

if [ -d "$ZED_DOCS_DIR" ]; then
  exit 0
fi

git clone \
  --depth 1 \
  --filter=blob:none \
  --sparse \
  https://github.com/zed-industries/zed.git \
  "$ZED_DOCS_DIR"

cd "$ZED_DOCS_DIR"
git sparse-checkout set docs/src