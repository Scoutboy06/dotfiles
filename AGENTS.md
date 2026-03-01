# Agents Guide (dotfiles)

This is a small, pragmatic dotfiles repository. There is no full build system
and no pinned test/lint toolchain; most changes are scripts and config files.

Primary areas:

- `install.py` (Python installer / module registry; wraps GNU Stow)
- `bin/.local/bin/*` (small CLI tools; mostly Python and bash)
- `*.sh` (shell scripts)
- `hypr/**`, `waybar/**`, `OpenTabletDriver/**`, `omarchy/**` (config/assets)

Cursor/Copilot rules:

- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md`
  found in this repo at the time of writing. If these appear later, treat them
  as higher-priority repo instructions and update this document.

## Build / Lint / Test

There is no formal test runner. Treat these commands as the repo's "smoke
checks" and "single test" equivalents.

Installer / Stow workflow:

- List configs + modules: `./install.py --list`
- Dry-run a full config install: `./install.py omarchy --dry-run --verbose`
- Install a config (writes symlinks): `./install.py omarchy`
- Run a single module (repeat `--only`): `./install.py --only waybar --dry-run --verbose`
- Restow after moving files: `./install.py omarchy --restow`

Notes:

- Stow-based modules require `stow` on PATH.
- Stow refuses to overwrite existing targets; do not weaken safety checks.

Python checks:

- Fast parse/bytecode check (repo-wide): `python3 -m compileall -q .`
- "Single test" for a script: run its smallest useful invocation, typically
  `--help` or a minimal input file:
  - `python3 bin/.local/bin/csvcut --help`
  - `python3 bin/.local/bin/md-convert --help`
  - `./install.py --help`

Shell checks:

- Syntax-only: `bash -n eduroam_setup.sh check-status.sh check-agents-sync.sh`
- "Single test" for a shell script:
  - `./eduroam_setup.sh --dry-run` (prints profile; does not require root)
  - `./check-agents-sync.sh` (no output on success; may notify via `notify-send`)

Optional lint/format (if installed locally):

- Python: `ruff check .` and `ruff format .`
- Shell: `shellcheck eduroam_setup.sh check-status.sh check-agents-sync.sh`

Practical "single test" patterns (no harness):

- Installer logic: `./install.py --only <module_id> --dry-run --verbose`
- A CLI change: run `--help` and one minimal "happy path" invocation
- A config change: run the owning app only if you already use it (Hyprland,
  Waybar, etc.); otherwise keep diffs minimal and avoid speculative rewrites

## Code Style

### General

- Keep changes small and local; avoid repo-wide refactors.
- Prefer safe, reversible operations (dry-run flags; no overwrites).
- Default to ASCII in new/edited files unless the file already uses Unicode.
- Do not add heavy new tooling (formatters/linters/build systems) unless
  clearly justified and documented here.

### Python

This repo's Python scripts are standalone CLIs (see `install.py` and
`bin/.local/bin/csvcut`). Match existing patterns.

Structure:

- Use `from __future__ import annotations`.
- Prefer a `main(argv: list[str]) -> int` and `raise SystemExit(main(...))`.
- Keep parsing in `parse_args()` and keep I/O at the edges.
- Prefer small, pure helper functions that are easy to exercise via CLI.

Imports:

- Standard library only by default; add third-party deps only when necessary.
- Import order: `__future__`, then stdlib, then local imports.
- Prefer `pathlib.Path` over string paths.

Types and data:

- Use built-in generics: `list[str]`, `dict[str, ...]`, `str | None`.
- Add explicit types on public functions and non-trivial locals.
- Use `@dataclass(frozen=True)` for simple records (see `install.py`).

Formatting:

- Keep lines readable; follow the existing style (similar to Black/Ruff).
- Prefer f-strings; avoid overly clever one-liners.

Naming:

- `snake_case` for functions/vars, `PascalCase` for types/classes.
- Be descriptive; abbreviate only common terms (`src`, `dst`, `tmp`).

Error handling and exits:

- Fail fast with clear messages.
- For CLIs:
  - print errors to stderr (`print(..., file=sys.stderr)`)
  - return non-zero exit codes; use `2` for usage/data errors when appropriate
- Prefer `subprocess.run(..., check=True)` and bubble up failures.

### Shell (bash)

New non-trivial scripts should use the safer baseline:

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail`
- Quote variables and paths: `"$var"`
- Prefer `printf` over `echo` for predictable output

CLI patterns:

- Provide `usage` and `die` helpers.
- Validate inputs; reject multi-line values when writing config files.
- For scripts writing secrets/configs:
  - use `read -s` for secrets
  - use `umask 077` and restrictive modes (`install -m 600`)
  - avoid printing secrets in dry-run output

When editing existing scripts, keep behavior stable even if they don't fully
follow the baseline (e.g. `check-status.sh` is intentionally small).

### Config files

- Preserve upstream conventions and formatting; keep diffs minimal.
- Hyprland: avoid reflowing lines; keep comments accurate.
- Waybar CSS: keep changes scoped; avoid unrelated reformatting.

## Security / Safety

- Never commit credentials, tokens, private keys, or machine-specific secrets.
- Treat `eduroam_setup.sh` as security-sensitive (writes config under `/var`).
- `install.py` is designed to be non-destructive; do not add overwrite behavior
  without a compelling reason.

## Working With This Repo

- Prefer dry-runs (`./install.py ... --dry-run --verbose`) before changing the
  live `$HOME` target tree.
- If you need to validate changes, pick the narrowest check that exercises the
  code path you touched ("single test" mindset).
- If you add new commands/workflows, update this file.
