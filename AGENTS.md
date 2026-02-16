# Agents Guide (dotfiles)

This repository is a small, pragmatic dotfiles setup. There is no full build
system, no dedicated test runner, and no repo-wide lint config checked in.
Most changes are to:

- `install.py` (Python installer / module registry)
- `scripts/*` (small CLI utilities, currently Python)
- `*.sh` (shell scripts)
- `hypr/**`, `waybar/**`, `OpenTabletDriver/**` (config/assets)

Cursor rules (`.cursor/rules/`, `.cursorrules`) and Copilot rules
(`.github/copilot-instructions.md`) are not present in this repo at the time of
writing.

## Common Commands

### Install / list modules

- List configs + modules:
  - `./install.py --list`
- Dry-run install (prints actions, does not write):
  - `./install.py omarchy --dry-run --verbose`
- Install a config:
  - `./install.py omarchy`
- Install a single module (repeat `--only` for more):
  - `./install.py --only waybar --dry-run --verbose`
- Restow after reorganizing files:
  - `./install.py omarchy --restow`

Notes:

- Stow-based modules require GNU Stow (`stow`) on PATH.
- `LinkFileModule` refuses to overwrite existing targets for safety.

### Smoke checks (what passes for “tests” here)

There is no `pytest`/`unittest` suite checked in. Use these lightweight checks
after edits:

- Validate Python parses/compiles:
  - `python3 -m compileall -q .`
- Run script help to ensure argument parsing still works:
  - `python3 scripts/csvcut --help`
  - `./install.py --help`
  - `./eduroam_setup.sh --help`
- If you touched `eduroam_setup.sh`, ensure dry-run output works:
  - `./eduroam_setup.sh --dry-run`

### Lint / format (optional but recommended)

No linters are pinned in-repo. If you have these tools locally:

- Python (recommended):
  - `ruff check .`
  - `ruff format .`
- Shell (recommended):
  - `shellcheck check-status.sh eduroam_setup.sh`

### “Single test” equivalents

Since there is no test runner, the closest single-test workflow is:

- For a Python function/script: run the smallest CLI invocation that covers it
  (usually `--help` or a minimal input file).
- For installer logic: `./install.py --only <module> --dry-run --verbose`.

## Code Style

### General

- Keep changes small and local; this is a personal dotfiles repo.
- Prefer safe, reversible operations (dry-run flags, no overwrites).
- Avoid introducing non-ASCII unless the file already uses it.
- Do not add repo-wide frameworks/tooling unless clearly necessary.

### Python (`install.py`, `scripts/csvcut`)

Formatting / structure (match existing files):

- Target runtime: `python3` (currently Python 3.13).
- Use `from __future__ import annotations`.
- Prefer `pathlib.Path` over string paths.
- Prefer explicit types on public functions and key locals.
- Use dataclasses for simple immutable records (`@dataclass(frozen=True)`).
- Keep I/O at the edges; keep pure helpers small and testable.

Imports:

- Standard library first; no third-party imports unless justified.
- Order: `__future__`, stdlib imports, then local imports.

Naming:

- `snake_case` for functions/vars, `PascalCase` for classes.
- Favor descriptive names over abbreviations (except common ones like `src`).

Error handling:

- Fail fast with clear messages.
- CLI scripts should:
  - print errors to stderr
  - return non-zero exit codes (e.g. `return 2` for usage/data errors)
- Prefer `subprocess.run(..., check=True)` when invoking commands.

### Shell (`*.sh`)

- Use `#!/usr/bin/env bash`.
- Prefer strict mode for non-trivial scripts: `set -euo pipefail`.
- Quote variables and paths: `"$var"`.
- Prefer small helper functions (`usage`, `die`, `require_root`).
- Treat secrets carefully:
  - use `read -s` for passwords
  - avoid echoing secrets
  - use restrictive permissions (`umask 077`, `install -m 600`)

### Config files (`hypr/**`, `waybar/**`, `OpenTabletDriver/**`)

- Preserve upstream conventions and formatting; keep diffs minimal.
- For Hyprland configs: keep comments accurate and avoid reflowing lines.
- For CSS: follow existing formatting; avoid large, unrelated refactors.

## Security / Safety

- Do not commit credentials, tokens, or private keys.
- Be careful with scripts that run as root (`eduroam_setup.sh`).
- `install.py` intentionally refuses to overwrite existing targets; do not
  weaken those checks without a compelling reason.

## Adding New Tooling

If you add lint/test tooling, keep it:

- opt-in (does not break existing workflows)
- documented here (update commands above)
- scoped (avoid heavyweight monorepo setups for a small dotfiles repo)
