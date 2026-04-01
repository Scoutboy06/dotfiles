#!/usr/bin/env bash

set -euo pipefail

# verify.sh - Check that required dependencies are installed
#
# Usage:
#   ./verify.sh           # Check all required commands
#   ./verify.sh --verbose # Also show what's present
#   ./verify.sh --fix     # Print install commands for missing packages

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

usage() {
  cat <<'EOF'
Usage: ./verify.sh [OPTIONS]

Check that required dependencies for this dotfiles repo are installed.

Options:
  --verbose    Show status of all commands (not just missing)
  --fix        Print install commands for missing packages
  --optional   Also check optional dependencies
  -h, --help   Show this help

Exit codes:
  0  All required dependencies found
  1  Some required dependencies missing
EOF
}

# Required commands and their typical package names
# Format: "command:package" or just "command" if same
REQUIRED_COMMANDS=(
  "git:git"
  "python3:python"
  "stow:stow"
  "hyprctl:hyprland"
  "hyprlock:hyprlock"
  "hypridle:hypridle"
  "waybar:waybar"
  "brightnessctl:brightnessctl"
  "iw:iw"
  "notify-send:libnotify"
  "pamixer:pamixer"
  "wl-copy:wl-clipboard"
  "uwsm:uwsm"
)

# Optional commands
OPTIONAL_COMMANDS=(
  "btop:btop"
  "snapper:snapper"
  "paccache:pacman-contrib"
  "ffmpeg:ffmpeg"
  "upower:upower"
  "docker:docker"
  "ghostty:ghostty"
  "1password:1password"
  "obsidian:obsidian"
  "spotify:spotify"
  "subl:sublime-text-4"
)

# Omarchy-specific commands (will be replaced in later phases)
OMARCHY_COMMANDS=(
  "omarchy-menu"
  "omarchy-launch-browser"
  "omarchy-launch-editor"
  "omarchy-launch-or-focus"
  "omarchy-launch-tui"
  "omarchy-launch-wifi"
  "omarchy-launch-bluetooth"
  "omarchy-launch-audio"
  "omarchy-lock-screen"
  "omarchy-toggle-idle"
  "omarchy-toggle-notification-silencing"
  "omarchy-update-available"
  "omarchy-voxtype-status"
  "omarchy-show-done"
)

check_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1
}

parse_entry() {
  local entry="$1"
  local -n cmd_ref="$2"
  local -n pkg_ref="$3"

  if [[ "$entry" == *:* ]]; then
    cmd_ref="${entry%%:*}"
    pkg_ref="${entry#*:}"
  else
    cmd_ref="$entry"
    pkg_ref="$entry"
  fi
}

main() {
  local verbose=false
  local fix=false
  local check_optional=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verbose)
        verbose=true
        shift
        ;;
      --fix)
        fix=true
        shift
        ;;
      --optional)
        check_optional=true
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        return 2
        ;;
    esac
  done

  local missing_required=()
  local missing_optional=()
  local missing_omarchy=()
  local missing_packages=()

  echo -e "${BLUE}Checking required dependencies...${NC}"
  echo

  # Check required commands
  for entry in "${REQUIRED_COMMANDS[@]}"; do
    local cmd pkg
    parse_entry "$entry" cmd pkg

    if check_command "$cmd"; then
      if $verbose; then
        echo -e "  ${GREEN}✓${NC} $cmd"
      fi
    else
      echo -e "  ${RED}✗${NC} $cmd (package: $pkg)"
      missing_required+=("$cmd")
      missing_packages+=("$pkg")
    fi
  done

  # Check optional commands
  if $check_optional; then
    echo
    echo -e "${BLUE}Checking optional dependencies...${NC}"
    echo

    for entry in "${OPTIONAL_COMMANDS[@]}"; do
      local cmd pkg
      parse_entry "$entry" cmd pkg

      if check_command "$cmd"; then
        if $verbose; then
          echo -e "  ${GREEN}✓${NC} $cmd"
        fi
      else
        echo -e "  ${YELLOW}○${NC} $cmd (package: $pkg)"
        missing_optional+=("$cmd")
      fi
    done
  fi

  # Check Omarchy commands
  echo
  echo -e "${BLUE}Checking Omarchy runtime...${NC}"
  echo

  local omarchy_found=0
  local omarchy_missing=0

  for cmd in "${OMARCHY_COMMANDS[@]}"; do
    if check_command "$cmd"; then
      ((omarchy_found++)) || true
      if $verbose; then
        echo -e "  ${GREEN}✓${NC} $cmd"
      fi
    else
      ((omarchy_missing++)) || true
      missing_omarchy+=("$cmd")
    fi
  done

  if [[ $omarchy_found -gt 0 && $omarchy_missing -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} Omarchy runtime detected (${omarchy_found} commands)"
  elif [[ $omarchy_found -gt 0 ]]; then
    echo -e "  ${YELLOW}○${NC} Partial Omarchy runtime (${omarchy_found}/${#OMARCHY_COMMANDS[@]} commands)"
  else
    echo -e "  ${YELLOW}○${NC} Omarchy runtime not installed"
    echo -e "    ${YELLOW}Note:${NC} Some keybinds and Waybar modules will not work."
    echo -e "    ${YELLOW}      ${NC} This will be fixed in later migration phases."
  fi

  # Check for OMARCHY_PATH environment variable
  echo
  if [[ -n "${OMARCHY_PATH:-}" ]]; then
    echo -e "  ${GREEN}✓${NC} \$OMARCHY_PATH is set: $OMARCHY_PATH"
  else
    echo -e "  ${YELLOW}○${NC} \$OMARCHY_PATH is not set"
  fi

  # Summary
  echo
  echo -e "${BLUE}Summary${NC}"
  echo "────────────────────────────────────"

  if [[ ${#missing_required[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} All required dependencies installed"
  else
    echo -e "  ${RED}✗${NC} Missing ${#missing_required[@]} required: ${missing_required[*]}"
  fi

  if $check_optional && [[ ${#missing_optional[@]} -gt 0 ]]; then
    echo -e "  ${YELLOW}○${NC} Missing ${#missing_optional[@]} optional: ${missing_optional[*]}"
  fi

  # Print fix commands
  if $fix && [[ ${#missing_packages[@]} -gt 0 ]]; then
    echo
    echo -e "${BLUE}Install missing packages:${NC}"
    echo

    # Deduplicate packages
    local unique_packages
    unique_packages=$(printf '%s\n' "${missing_packages[@]}" | sort -u | tr '\n' ' ')

    echo "  sudo pacman -S --needed $unique_packages"
    echo
    echo -e "  ${YELLOW}Note:${NC} Some packages may be in the AUR. Check manifests/packages-aur.txt"
  fi

  # Exit code
  if [[ ${#missing_required[@]} -gt 0 ]]; then
    return 1
  fi
  return 0
}

main "$@"
