# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Used across several machines and OSes (Arch/Omarchy, Ubuntu, WSL, Windows) to keep a consistent environment.

## Quick start

### Linux

Install chezmoi:

```bash
# Arch
sudo pacman -S chezmoi

# Debian/Ubuntu (or any distro without a recent package)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

Then install the dotfiles:

```bash
git clone git@github.com:Scoutboy06/dotfiles.git ~/p/dotfiles
chezmoi init --source ~/p/dotfiles --apply
```

### Windows

Windows doesn't run chezmoi — only the package install script at the repo root:

```powershell
git clone git@github.com:Scoutboy06/dotfiles.git
cd dotfiles
.\install-windows-packages.ps1
```

## Machines

Machine detection lives in `.chezmoi.toml.tmpl`, keyed on hostname:

| Hostname | Device | Template variable |
|----------|--------|-------------------|
| `eliaspc` / `EliasPC` | Desktop | `.isDesktop` |
| `eliaslt` / `EliasLT` | Laptop | `.isLaptop` |
| `HQ-LAP-103` | Work laptop | `.isWorkLaptop` |

Other template variables available in `.tmpl` files: `.device`, `.isOmarchy`, `.hasDE` (false on WSL/servers), `.monitorScale`, `.primaryMonitor`, `.editor`.

Machine-specific file exclusions (e.g. laptop-only battery monitor, eduroam) are in `.chezmoiignore`.

## Everyday commands

```bash
chezmoi diff                       # preview what apply would change
chezmoi apply                      # apply everything
chezmoi apply --exclude=scripts    # apply configs only, skip install scripts
chezmoi edit ~/.zshrc              # edit the source file behind a target
chezmoi add ~/.config/app/x.toml   # start managing a new file
chezmoi cd                         # jump to ~/p/dotfiles
chezmoi execute-template < my_template.tmpl   # preview how a template renders
```

## Packages

Package definitions live in `.packages/`, one YAML per manager, with entries filtered by `device` and `environment`:

| File | Installed with |
|------|----------------|
| `packages-pacman.yaml` | pacman (Arch) |
| `packages-aur.yaml` | paru (Arch/AUR) |
| `packages-apt.yaml` | apt (Debian/Ubuntu) |
| `packages-bun.yaml` | bun (global packages) |
| `packages-winget.yaml` | winget (Windows) |
| `custom-arch-packages.yaml` | makepkg from remote PKGBUILDs (Arch only) |

The install scripts are `run_onchange_` — editing any package YAML re-runs them on the next `chezmoi apply`.

## What's configured

- **Shell**: zsh with starship, zoxide, fzf, direnv, eza
- **Desktop**: Omarchy 4 with Lua-based Hyprland configuration and the Omarchy shell
- **Apps**: assorted configs under `dot_config/`
- **Scripts**: Hyprland helpers and general utilities in `dot_local/bin/`
- **Agent skills**: shared AI agent skills, symlinked into `~/.claude/skills`

## Repo layout

```
.
├── .chezmoi.toml.tmpl            # Machine detection + template data
├── .packages/                    # Package definitions, one YAML per manager
├── .chezmoiscripts/              # run_once_* setup + run_onchange_* package installs
├── .chezmoiignore                # Per-machine file exclusions
├── dot_zshrc.tmpl                # Zsh configuration
├── dot_config/                   # ~/.config configuration files
├── dot_local/
│   ├── bin/                      # Custom scripts and executables
│   └── share/
│       └── applications/         # Desktop entry files for applications
├── dot_agents/
│   └── skills/                   # Skills shared between AI agents
├── dot_claude/
│   └── symlink_skills/           # Symlink of dot_agents/skills into ~/.claude
├── install-windows-packages.ps1  # Windows package installation
├── AGENTS.md                     # Agent instructions (repo file, not deployed)
└── CODE.md                       # Structure/convention requirements for agents
```

## Notes

- Local zsh overrides go in `~/.zshrc.local` (not tracked).
- `~/.config/mimeapps.list` is partially managed by `modify_mimeapps.list.tmpl`; edit its tracked defaults in `.chezmoidata/mimeapps.yaml`.
- Merge conflicts open in VS Code via the custom `[merge]` command in `.chezmoi.toml.tmpl`.
- Hyprland configs originally adapted from [Omarchy](https://github.com/basecamp/omarchy).
