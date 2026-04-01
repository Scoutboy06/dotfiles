#!/usr/bin/env bash

set -euo pipefail

# bootstrap.sh - System setup for dotfiles
#
# This script helps set up a new machine by:
# 1. Installing required packages
# 2. Installing AUR packages (if AUR helper available)
# 3. Deploying dotfiles via install.py
# 4. Enabling systemd user services
#
# Usage:
#   ./bootstrap.sh              # Interactive mode
#   ./bootstrap.sh --dry-run    # Print what would be done
#   ./bootstrap.sh --help       # Show help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  BOLD=''
  NC=''
fi

DRY_RUN=false
SKIP_PACMAN=false
SKIP_AUR=false
SKIP_STOW=false
SKIP_SERVICES=false
CONFIG="omarchy"

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [OPTIONS]

Bootstrap a new machine with this dotfiles configuration.

Options:
  --dry-run        Print what would be done, but don't execute
  --config NAME    Config to install (default: omarchy)
  --skip-pacman    Skip pacman package installation
  --skip-aur       Skip AUR package installation
  --skip-stow      Skip dotfiles deployment (install.py)
  --skip-services  Skip systemd service enablement
  -h, --help       Show this help

Steps:
  1. Install required packages (pacman)
  2. Install AUR packages (if paru/yay available)
  3. Deploy dotfiles (./install.py <config>)
  4. Enable systemd user services

Run ./verify.sh first to see what's missing.
EOF
}

log() {
  echo -e "${BLUE}==>${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}==> Warning:${NC} $*"
}

log_error() {
  echo -e "${RED}==> Error:${NC} $*" >&2
}

log_cmd() {
  echo -e "    ${BOLD}\$${NC} $*"
}

run_cmd() {
  log_cmd "$*"
  if ! $DRY_RUN; then
    "$@"
  fi
}

confirm() {
  local prompt="$1"
  local response

  if $DRY_RUN; then
    return 0
  fi

  echo -en "${YELLOW}$prompt [y/N]${NC} "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

read_manifest() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return
  fi
  grep -v '^\s*#' "$file" | grep -v '^\s*$' || true
}

detect_aur_helper() {
  for helper in paru yay pikaur; do
    if command -v "$helper" >/dev/null 2>&1; then
      echo "$helper"
      return 0
    fi
  done
  return 1
}

install_pacman_packages() {
  local manifest="$SCRIPT_DIR/manifests/packages.txt"

  if [[ ! -f "$manifest" ]]; then
    log_warn "No packages.txt manifest found, skipping pacman packages"
    return 0
  fi

  local packages
  packages=$(read_manifest "$manifest")

  if [[ -z "$packages" ]]; then
    log "No packages to install from packages.txt"
    return 0
  fi

  log "Installing required packages via pacman..."
  echo

  # Show what will be installed
  echo "$packages" | while read -r pkg; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} $pkg (installed)"
    else
      echo -e "  ${YELLOW}○${NC} $pkg (will install)"
    fi
  done

  echo
  if confirm "Install packages with pacman?"; then
    # shellcheck disable=SC2086
    run_cmd sudo pacman -S --needed $packages
  else
    log "Skipping pacman packages"
  fi
}

install_aur_packages() {
  local manifest="$SCRIPT_DIR/manifests/packages-aur.txt"

  if [[ ! -f "$manifest" ]]; then
    log_warn "No packages-aur.txt manifest found, skipping AUR packages"
    return 0
  fi

  local helper
  if ! helper=$(detect_aur_helper); then
    log_warn "No AUR helper found (paru, yay, pikaur). Skipping AUR packages."
    log_warn "Install an AUR helper and re-run, or install AUR packages manually."
    return 0
  fi

  local packages
  packages=$(read_manifest "$manifest")

  if [[ -z "$packages" ]]; then
    log "No packages to install from packages-aur.txt"
    return 0
  fi

  log "Installing AUR packages via $helper..."
  echo

  # Show what will be installed
  echo "$packages" | while read -r pkg; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} $pkg (installed)"
    else
      echo -e "  ${YELLOW}○${NC} $pkg (will install)"
    fi
  done

  echo
  if confirm "Install AUR packages with $helper?"; then
    # shellcheck disable=SC2086
    run_cmd "$helper" -S --needed $packages
  else
    log "Skipping AUR packages"
  fi
}

deploy_dotfiles() {
  log "Deploying dotfiles configuration: $CONFIG"
  echo

  if $DRY_RUN; then
    run_cmd "$SCRIPT_DIR/install.py" "$CONFIG" --dry-run --verbose
  else
    if confirm "Deploy dotfiles with ./install.py $CONFIG?"; then
      run_cmd "$SCRIPT_DIR/install.py" "$CONFIG"
    else
      log "Skipping dotfiles deployment"
    fi
  fi
}

enable_services() {
  local manifest="$SCRIPT_DIR/manifests/services-user.txt"

  if [[ ! -f "$manifest" ]]; then
    log_warn "No services-user.txt manifest found, skipping service enablement"
    return 0
  fi

  local services
  services=$(read_manifest "$manifest")

  if [[ -z "$services" ]]; then
    log "No services to enable from services-user.txt"
    return 0
  fi

  log "Enabling systemd user services..."
  echo

  # Show what will be enabled
  echo "$services" | while read -r svc; do
    if systemctl --user is-enabled "$svc" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} $svc (enabled)"
    else
      echo -e "  ${YELLOW}○${NC} $svc (will enable)"
    fi
  done

  echo
  if confirm "Enable systemd user services?"; then
    echo "$services" | while read -r svc; do
      run_cmd systemctl --user enable --now "$svc" || true
    done
  else
    log "Skipping service enablement"
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --config)
        CONFIG="$2"
        shift 2
        ;;
      --skip-pacman)
        SKIP_PACMAN=true
        shift
        ;;
      --skip-aur)
        SKIP_AUR=true
        shift
        ;;
      --skip-stow)
        SKIP_STOW=true
        shift
        ;;
      --skip-services)
        SKIP_SERVICES=true
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage >&2
        return 2
        ;;
    esac
  done

  echo -e "${BOLD}Dotfiles Bootstrap${NC}"
  echo "════════════════════════════════════"
  echo

  if $DRY_RUN; then
    echo -e "${YELLOW}DRY RUN MODE - no changes will be made${NC}"
    echo
  fi

  # Step 1: Pacman packages
  if ! $SKIP_PACMAN; then
    install_pacman_packages
    echo
  fi

  # Step 2: AUR packages
  if ! $SKIP_AUR; then
    install_aur_packages
    echo
  fi

  # Step 3: Deploy dotfiles
  if ! $SKIP_STOW; then
    deploy_dotfiles
    echo
  fi

  # Step 4: Enable services
  if ! $SKIP_SERVICES; then
    enable_services
    echo
  fi

  log "Bootstrap complete!"
  echo
  echo "Next steps:"
  echo "  1. Run ./verify.sh to check for missing dependencies"
  echo "  2. Log out and back in (or reboot) to apply changes"
  echo "  3. Check ~/.config/omarchy/trusted-ssids.txt for idle-lock config"
  echo
  echo -e "${YELLOW}Note:${NC} Some features require the Omarchy runtime."
  echo "      These will be migrated in later phases."
}

main "$@"
