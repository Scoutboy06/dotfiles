# dotfiles

Personal dotfiles/config repo managed with GNU Stow via `install.py`.

## Quick Start (New Machine)

```bash
git clone git@github.com:Scoutboy06/dotfiles.git
cd dotfiles

# Check what's needed
./verify.sh

# Bootstrap the system (installs packages, deploys configs, enables services)
./bootstrap.sh

# Or do it step by step - see "Manual Install" below
```

## Manual Install

### Prerequisites

- `python3`
- `stow` (GNU Stow)
- See `manifests/packages.txt` for full list

### Deploy configs

List available configs/modules:

```bash
./install.py --list
```

Dry-run an install (prints actions/commands):

```bash
./install.py omarchy --dry-run --verbose
```

Install a config:

```bash
./install.py omarchy
```

Install a single module:

```bash
./install.py --only hypr
```

After reorganizing files, restow:

```bash
./install.py omarchy --restow
```

### Enable services

After deploying configs, enable the systemd user services:

```bash
systemctl --user enable --now disk-usage-watch.timer
systemctl --user enable --now omarchy-idle-lock-auto.timer
```

Or use bootstrap.sh which does this automatically.

## Verify Dependencies

Check that required commands are installed:

```bash
./verify.sh              # Check required deps
./verify.sh --verbose    # Also show what's present
./verify.sh --optional   # Include optional deps
./verify.sh --fix        # Print install commands for missing packages
```

## Package Manifests

Machine-readable dependency lists live in `manifests/`:

| File | Purpose |
|------|---------|
| `packages.txt` | Required pacman packages |
| `packages-optional.txt` | Optional pacman packages |
| `packages-aur.txt` | AUR packages |
| `services-user.txt` | Systemd user services to enable |
| `fonts.txt` | Required fonts |
| `pip.txt` | Python pip packages |

Install required packages:

```bash
sudo pacman -S --needed $(grep -v '^#' manifests/packages.txt | tr '\n' ' ')
```

## Notes

- Packages mirror the expected paths under `$HOME` (e.g. `waybar/.config/waybar/...`).
- `install.py` runs `stow` with `--target ~` and refuses to overwrite existing targets.
- If you are migrating from an older layout, you may need to remove old symlinks first.

### Omarchy Compatibility

This config was originally designed for the Omarchy desktop environment. Some features
(keybinds, Waybar modules) currently depend on Omarchy runtime commands. If you don't
have Omarchy installed, run `./verify.sh` to see what's missing.

Migration to standalone operation is in progress.

## Other Scripts

- `eduroam_setup.sh`: generates an iwd eduroam profile under `/var/lib/iwd/` (use `--dry-run` to print without writing).
- `check-status.sh`: shows a desktop notification if this repo has uncommitted changes.
- `verify.sh`: checks that required dependencies are installed.
- `bootstrap.sh`: sets up a new machine (packages, dotfiles, services).

### User scripts (in `bin/.local/bin/`)

- `csvcut`: select columns from CSV files by header name.
- `md-convert`: recursively convert `.html` files to Markdown (requires `markdownify`).
- `snapper-cleanup`: aggressively cleans up Btrfs snapshots (requires root, `snapper`).
- `disk-usage-watch`: monitor disk usage and send notifications.
- `battery-tui`: display battery info in a TUI.
- `disk-cleanup`: interactive disk cleanup tool.

## Project Structure

```
dotfiles/
├── install.py              # Module registry + installer (GNU Stow)
├── verify.sh               # Dependency checker
├── bootstrap.sh            # System setup script
├── manifests/              # Package/service manifests
│   ├── packages.txt
│   ├── packages-optional.txt
│   ├── packages-aur.txt
│   ├── services-user.txt
│   ├── fonts.txt
│   └── pip.txt
├── hypr/                   # Hyprland config
├── waybar/                 # Waybar config
├── omarchy/                # Omarchy theme + systemd services
├── bin/                    # User scripts (~/.local/bin)
├── OpenTabletDriver/       # Drawing tablet config
├── sublime-text/           # Sublime Text config
├── agents/                 # AI agent skills (~/.agents)
└── network/                # Network assets (not stowed)
```

More contributor/workflow notes live in `AGENTS.md`.
