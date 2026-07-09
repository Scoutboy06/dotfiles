# CODE.md - dotfiles

## Project Overview

Custom dotfiles for personal use, including configurations for various tools and applications. Used on a variety of computers and operating systems to maintain a consistent development environment.

## Repository Structure

```
.
├── README.md                     # Project documentation and overview
├── .chezmoi.toml.tmpl            # Machine detection; generates ~/.config/chezmoi/chezmoi.toml with template data
├── .packages/                    # Package definitions, read by the install scripts (see its CODE.md)
├── .chezmoiscripts/              # Scripts run by chezmoi apply, not deployed to $HOME (see section below)
├── .chezmoiignore                # Targets chezmoi must not deploy; templated for per-machine exclusions
├── dot_agents/                   # Configurations for various agents and tools
│   └── skills/                   # Skills and configurations for different agents
├── dot_claude/                   # Configurations specific to the Claude agent
│   └── symlink_skills/           # A direct symlink of dot_agents/skills/
├── dot_config/                   # Configuration files
├── dot_local/                    # Local configuration files and scripts
│   ├── bin/                      # Custom scripts and executables
│   └── share/                    # Shared resources and data files
│       └── applications/         # Desktop entry files for applications
├── dot_zshrc.tmpl                # Zsh configuration
└── install-windows-packages.ps1  # PowerShell script for installing Windows packages
```

## Chezmoi Naming Conventions

This is a chezmoi source directory: filenames encode target state attributes
(see https://www.chezmoi.io/reference/target-types/). Never rename a file without
preserving the prefixes/suffixes it needs.

Prefixes (applied in this order when combined):

| Prefix | Effect on target |
|--------|------------------|
| `create_` | Create only if target does not already exist |
| `modify_` | Script whose output modifies the existing target file |
| `remove_` | Remove the target |
| `run_` | Script executed by `chezmoi apply` (see `.chezmoiscripts/CODE.md`) |
| `exact_` | (directories) Delete anything in the target dir not managed here |
| `encrypted_` | Source file is encrypted |
| `private_` | Clear group/world permissions (0600/0700) |
| `readonly_` | Clear write permissions |
| `empty_` | Keep the target file even if its contents are empty |
| `executable_` | Set executable bits |
| `symlink_` | Target is a symlink; file contents are the link destination |
| `dot_` | Target name starts with `.` (`dot_zshrc` → `~/.zshrc`) |

Suffix: `.tmpl` — file is a Go template rendered with the data from `.chezmoi.toml.tmpl`
and `.chezmoidata/`. The suffix is stripped from the target name.

## .chezmoiscripts

Chezmoi requires every file in `.chezmoiscripts/` to be a `run_*` script, so this
section lives here instead of a CODE.md in that directory — do not create one there.

The filename controls when a script runs: `run_<when>_[<order>_]<name>.sh[.tmpl]`

- `<when>`: `once` — runs a single time per machine (tracked by content hash);
  `onchange` — re-runs whenever the rendered script contents change.
- `<order>` (optional): `before` — before files are updated; `after` — after
  all files are updated. Omitted means unordered, alongside file updates.
- `.tmpl` suffix: rendered as a Go template before execution. Use this for
  anything that branches on `.device`, `.hasDE`, `.isOmarchy`, etc. —
  filter at template time so the shipped script is minimal.

Conventions:

- Bash with `set -euo pipefail`.
- Refuse to run as root (`$EUID` check) — scripts use sudo internally where needed.
- Use the shared log helper style: `log_info` / `log_success` / `log_warn` / `log_error` with ANSI colors.
- `run_onchange_` scripts that depend on `.packages/` files MUST embed a
  hash comment per file (`# <file>: {{ include "<path>" | sha256sum }}`) so
  data changes re-trigger the script.
- Scripts must be idempotent: check current state before changing it
  (package already installed, service already enabled, etc.).
- Package installation belongs in `.packages/` YAML files, not in new scripts.

## Agent Behavior

- Do not read files to verify changes you just made, trust the edit.
- Batch independent tool calls in parallel to minimize round-trips.
