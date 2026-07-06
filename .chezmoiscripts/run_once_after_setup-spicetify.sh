#!/usr/bin/env bash
set -euo pipefail

# Guard: skip if spicetify isn't installed
if ! command -v spicetify &>/dev/null; then
    echo "[INFO] spicetify not found — skipping Spicetify setup"
    exit 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_success() { echo -e "${BLUE}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

main() {
    log_info "Setting up Spicetify..."
    echo ""

    local hook_failed=0

    # Set write permissions for Spotify and Apps directory
    log_info "Setting write permissions for Spotify and Apps directory"
    if sudo chmod a+wr /opt/spotify && sudo chmod a+wr /opt/spotify/Apps -R; then
        log_success "Permissions set successfully"
    else
        local exit_code=$?
        log_error "Failed to set permissions (exit code $exit_code)"
        hook_failed=1
    fi
    echo ""

    # # Initialize Spicetify
    log_info "Initializing Spicetify"
    if spicetify backup apply; then
        log_success "Spicetify initialized successfully"
    else
        local exit_code=$?
        log_error "Failed to initialize Spicetify (exit code $exit_code)"
        hook_failed=1
    fi
    # echo ""

    # # Install Spicetify Marketplace
    log_info "Installing Spicetify Marketplace"
    if curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh; then
        log_success "Spicetify Marketplace installed successfully"
    else
        local exit_code=$?
        log_error "Failed to install Spicetify Marketplace (exit code $exit_code)"
        hook_failed=1
    fi
    # echo ""

    if [[ $hook_failed -eq 0 ]]; then
        log_success "Spicetify setup completed successfully!"
    else
        log_warn "Spicetify setup had some failures (but continuing)"
        return 1
    fi
}

main "$@"