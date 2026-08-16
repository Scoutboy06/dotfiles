#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_success() { echo -e "${BLUE}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    log_error "Do not run this script as root"
    exit 1
fi

nvim_dir="$HOME/.config/nvim"

if [[ -e "$nvim_dir" || -L "$nvim_dir" ]]; then
    log_warn "$nvim_dir already exists; leaving it unchanged"
    exit 0
fi

if ! command -v git &>/dev/null; then
    log_error "git is required to bootstrap LazyVim"
    exit 1
fi

log_info "Cloning the LazyVim starter into $nvim_dir"
config_dir=$(dirname "$nvim_dir")
mkdir -p "$config_dir"
temp_dir=$(mktemp -d "$config_dir/.nvim-starter.XXXXXX")
trap 'rm -rf "$temp_dir"' EXIT

git clone --depth 1 https://github.com/LazyVim/starter "$temp_dir"
rm -rf "$temp_dir/.git"
mv "$temp_dir" "$nvim_dir"
trap - EXIT
log_success "LazyVim starter installed"
