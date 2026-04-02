# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) for Arch Linux machines.

## Quick Start (New Machine)

```bash
# Install chezmoi and initialize from this repo
chezmoi init --apply git@github.com:Scoutboy06/dotfiles.git

# Or if chezmoi is already installed
chezmoi init --apply Scoutboy06
```

On first run, chezmoi will:
1. Create common home directories (Documents, Downloads, Pictures, etc.)
2. Detect your machine (desktop `eliaspc` or laptop `eliaslt`)
3. Install packages via pacman/paru (including zsh, neovim, etc.)
4. Generate machine-specific configs (monitors, packages, etc.)
5. Set zsh as your default shell
6. Deploy neovim with LazyVim configuration

## What's Included

### Shell (zsh)
- **Zsh** with sensible defaults (history, completion, key bindings)
- **Starship** prompt with git status, language versions, cmd duration
- **eza** for better `ls` with icons
- **zoxide** for smarter `cd` (remembers directories)
- **fzf** for fuzzy finding
- **direnv** for per-directory environment variables

### Editor (neovim)
- **LazyVim** distribution - batteries included
- Auto-installs plugins on first launch
- LSP, treesitter, telescope, and more
- Tokyo Night colorscheme

### Desktop (Hyprland)
- Hyprland window manager with custom keybindings
- Waybar status bar
- Screenshot/screenrecord scripts
- Idle lock with hyprlock

## Manual Setup

### Prerequisites

- `chezmoi` (install with `pacman -S chezmoi`)
- `paru` or `yay` (for AUR packages)

### Apply configs

Preview changes before applying:

```bash
chezmoi diff
```

Apply all configs:

```bash
chezmoi apply
```

Apply without running scripts (packages, shell change):

```bash
chezmoi apply --exclude=scripts
```

### Add/edit configs

Edit a managed file:

```bash
chezmoi edit ~/.config/hypr/bindings.conf
```

Add a new file to be managed:

```bash
chezmoi add ~/.config/someapp/config.toml
```

### Enable services

After applying configs, enable the systemd user services:

```bash
systemctl --user enable --now disk-usage-watch.timer
systemctl --user enable --now idle-lock-auto.timer

# Laptop only
systemctl --user enable --now battery-monitor.timer
```

## Machine-Specific Configuration

Chezmoi uses templates for machine-specific configs. The machine is detected via hostname:

| Hostname | Type | Monitor Scale | Primary Monitor |
|----------|------|---------------|-----------------|
| `eliaspc` | Desktop | 1 | DP-1 |
| `eliaslt` | Laptop | 1.6 | eDP-1 |

Template variables are defined in `.chezmoi.toml.tmpl` and available in `.tmpl` files:
- `{{ .isDesktop }}` / `{{ .isLaptop }}`
- `{{ .monitorScale }}`
- `{{ .primaryMonitor }}`

### Machine-specific files

Some files are only deployed on certain machines (via `.chezmoiignore`):
- `battery-monitor.service/timer` - laptop only
- `.config/eduroam/` - laptop only

## Packages

Packages are defined in `.chezmoidata/packages.yaml`:

```yaml
common:    # All machines (pacman)
aur:       # All machines (AUR)
desktop:   # Desktop only
laptop:    # Laptop only
optional:  # Not auto-installed
```

The package install script runs automatically when `packages.yaml` changes.

Key packages installed:
- **Shell**: zsh, starship, eza, zoxide, fzf, direnv
- **Editor**: neovim, ripgrep, fd
- **Desktop**: hyprland, waybar, hyprlock, hypridle
- **Utils**: grim, slurp, satty (screenshots), gpu-screen-recorder

## Scripts

### Keybinding scripts (in `~/.local/bin/`)

| Script | Description | Keybinding |
|--------|-------------|------------|
| `screenshot` | Smart screenshot (region/window/fullscreen) | `Print`, `Super+Print`, `Super+Shift+Print` |
| `screenrecord` | Screen recording with audio options | `Super+Alt+Print` |
| `brightness-display` | Display brightness control | `XF86MonBrightnessUp/Down` |
| `audio-switch` | Cycle audio outputs | `Super+Mute` |
| `hyprland-gaps-toggle` | Toggle window gaps | `Super+G` |
| `lock-screen` | Lock with hyprlock | `Super+Shift+L` |

### Utility scripts

| Script | Description |
|--------|-------------|
| `csvcut` | Select CSV columns by header name |
| `md-convert` | Convert HTML files to Markdown |
| `snapper-cleanup` | Aggressive Btrfs snapshot cleanup |
| `disk-usage-watch` | Monitor disk usage with notifications |
| `disk-cleanup` | Interactive disk cleanup tool |
| `battery-tui` | Battery info TUI |
| `eduroam-setup` | Generate iwd eduroam profile (laptop) |
| `check-agents-sync` | Check if agent skills need syncing |
| `check-status` | Notify if dotfiles repo has uncommitted changes |

## Project Structure

```
dotfiles/                          # chezmoi source directory
├── .chezmoi.toml.tmpl             # Machine detection template
├── .chezmoidata/
│   └── packages.yaml              # Package definitions
├── .chezmoiscripts/
│   ├── run_once_before_create-directories.sh
│   ├── run_onchange_before_install-packages.sh.tmpl
│   └── run_once_after_set-default-shell.sh
├── .chezmoiignore                 # Files to skip per-machine
├── dot_zshrc                      # Zsh configuration
├── dot_config/
│   ├── nvim/                      # Neovim (LazyVim)
│   ├── starship.toml              # Starship prompt
│   ├── hypr/                      # Hyprland configs
│   │   ├── monitors.conf.tmpl     # Machine-specific monitors
│   │   └── bindings.conf          # Keybindings
│   ├── waybar/                    # Waybar config + scripts
│   ├── themes/elias-jade/         # Custom theme
│   ├── systemd/user/              # Systemd user services
│   ├── idle-lock/                 # Idle lock config
│   ├── OpenTabletDriver/          # Drawing tablet (desktop)
│   └── sublime-text/              # Sublime Text syntax
├── dot_local/bin/                 # User scripts
└── dot_agents/skills/             # AI agent skills
```

## Customization

### Zsh
Add local overrides to `~/.zshrc.local` (not tracked by chezmoi).

### Neovim
Add custom plugins in `~/.config/nvim/lua/plugins/`.
The config uses LazyVim - see [lazyvim.org](https://www.lazyvim.org/) for documentation.

### Starship
Edit `~/.config/starship.toml` or use `chezmoi edit ~/.config/starship.toml`.

## Notes

- Configs adapted from [Omarchy](https://github.com/basecamp/omarchy) with standalone operation
- See `AGENTS.md` for contributor/workflow notes
