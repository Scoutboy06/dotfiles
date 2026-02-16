# dotfiles

Personal dotfiles/config repo managed with GNU Stow via `install.py`.

## Install

Prereqs:

- `python3`
- `stow` (GNU Stow)

Clone anywhere:

```bash
git clone git@github.com:Scoutboy06/dotfiles.git
cd dotfiles
```

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

Notes:

- Packages mirror the expected paths under `$HOME` (e.g. `waybar/.config/waybar/...`).
- `install.py` runs `stow` with `--target ~` and refuses to overwrite existing targets.

## Other scripts

- `eduroam_setup.sh`: generates an iwd eduroam profile under `/var/lib/iwd/` (use `--dry-run` to print without writing).
- `check-status.sh`: shows a desktop notification if this repo has uncommitted changes.
- `bin/.local/bin/csvcut`: small helper CLI installed to `~/.local/bin/csvcut` by `install.py`.

## Project structure

- `install.py`: module registry + installer (GNU Stow)
- `hypr/.config/hypr/`: Hyprland config
- `waybar/.config/waybar/`: Waybar config
- `OpenTabletDriver/.config/OpenTabletDriver/`: OpenTabletDriver config
- `bin/.local/bin/`: user scripts installed to `~/.local/bin`
- `network/`: network-related assets (e.g. eduroam CA cert)

More contributor/workflow notes live in `AGENTS.md`.
