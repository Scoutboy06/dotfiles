# Agents Guide (dotfiles)

This is a small, pragmatic dotfiles repository managed by **chezmoi**. There is
no formal test runner; most changes are scripts and config files.

Primary areas:

- `.chezmoi*.tmpl` (chezmoi config + templates)
- `.chezmoiscripts/` (run scripts executed during `chezmoi apply`)
- `dot_local/bin/` (CLI tools; Python and bash)
- `dot_config/` (app configs: hypr, waybar, nvim, etc.)
- `dot_agents/` (agent skills)

Cursor/Copilot rules:

- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md`
  found. If these appear later, treat them as higher-priority instructions.

## Build / Lint / Test

There is no formal test runner. Use these commands as "smoke checks."

### Chezmoi workflow

- Preview changes: `chezmoi diff`
- Dry-run apply: `chezmoi apply --dry-run --verbose`
- Apply changes: `chezmoi apply`
- Re-add modified target: `chezmoi re-add ~/.config/waybar/config.jsonc`
- Edit source directly: `chezmoi edit ~/.local/bin/csvcut`

Notes:

- Template files (`*.tmpl`) are rendered using `.chezmoi.toml.tmpl` data.
- Files in `.chezmoiignore` are excluded from the target.
- `executable_*` prefix makes files executable in the target.

### Python checks

- Fast parse check (repo-wide): `python3 -m compileall -q .`
- "Single test" for a script: run `--help` or a minimal invocation:
  - `python3 dot_local/bin/executable_csvcut --help`
  - `python3 dot_local/bin/executable_md-convert --help`

### Shell checks

- Syntax-only: `bash -n dot_local/bin/executable_check-status`
- "Single test" examples:
  - `dot_local/bin/executable_check-agents-sync` (no output on success)
  - Waybar scripts: `bash -n dot_config/waybar/scripts/executable_toggle-idle.sh`

### Optional lint/format (if installed)

- Python: `ruff check .` and `ruff format .`
- Shell: `shellcheck dot_local/bin/executable_*`

### Practical "single test" patterns

- A CLI change: run `--help` and one minimal "happy path" invocation
- A config change: run the owning app if you use it (Hyprland, Waybar);
  otherwise keep diffs minimal and avoid speculative rewrites
- Template changes: `chezmoi execute-template < file.tmpl` to test rendering

## Code Style

### General

- Keep changes small and local; avoid repo-wide refactors.
- Prefer safe, reversible operations (dry-run flags; no overwrites).
- Default to ASCII unless the file already uses Unicode.
- Do not add heavy tooling without clear justification.

### Python

Scripts are standalone CLIs (see `executable_csvcut`, `executable_md-convert`).

Structure:

- Use `from __future__ import annotations`.
- Prefer `main(argv: list[str]) -> int` with `raise SystemExit(main(...))`.
- Keep parsing in `parse_args()` and keep I/O at the edges.
- Prefer small, pure helper functions exercisable via CLI.

Imports:

- Standard library only by default; add third-party deps only when necessary.
- Import order: `__future__`, then stdlib, then local imports.
- Prefer `pathlib.Path` over string paths.

Types and data:

- Use built-in generics: `list[str]`, `dict[str, ...]`, `str | None`.
- Add explicit types on public functions and non-trivial locals.
- Use `@dataclass(frozen=True)` for simple records.

Formatting:

- Keep lines readable; follow existing style (similar to Black/Ruff).
- Prefer f-strings; avoid overly clever one-liners.

Naming:

- `snake_case` for functions/vars, `PascalCase` for types/classes.
- Be descriptive; abbreviate only common terms (`src`, `dst`, `tmp`).

Error handling:

- Fail fast with clear messages.
- Print errors to stderr (`print(..., file=sys.stderr)`).
- Return non-zero exit codes; use `2` for usage/data errors.
- Prefer `subprocess.run(..., check=True)` and bubble up failures.

### Shell (bash)

New non-trivial scripts should use the safer baseline:

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail`
- Quote variables and paths: `"$var"`
- Prefer `printf` over `echo` for predictable output

CLI patterns:

- Provide `usage` and `die` helpers (see `executable_eduroam-setup.tmpl`).
- Validate inputs; reject multi-line values when writing config files.
- For scripts writing secrets/configs:
  - use `read -s` for secrets
  - use `umask 077` and restrictive modes (`install -m 600`)
  - avoid printing secrets in dry-run output

When editing existing scripts, keep behavior stable even if they don't fully
follow the baseline (e.g. `executable_check-status` is intentionally small).

### Config files

- Preserve upstream conventions and formatting; keep diffs minimal.
- Hyprland (`dot_config/hypr/`): avoid reflowing lines; keep comments accurate.
- Waybar CSS: keep changes scoped; avoid unrelated reformatting.
- Use chezmoi templates (`*.tmpl`) for machine-specific values.

### Chezmoi conventions

- Prefix executable files with `executable_` (not chmod).
- Use `dot_` prefix for hidden files/directories.
- Template files use Go template syntax: `{{ .variableName }}`.
- Machine-specific logic goes in `.chezmoi.toml.tmpl` and `.chezmoiignore`.

## Security / Safety

- Never commit credentials, tokens, private keys, or machine-specific secrets.
- Treat `executable_eduroam-setup.tmpl` as security-sensitive (writes to `/var`).
- Use `.chezmoiignore` to exclude machine-specific or sensitive files.

## Working With This Repo

- Prefer dry-runs (`chezmoi apply --dry-run --verbose`) before applying changes.
- Use `chezmoi diff` to preview what will change.
- Pick the narrowest check that exercises the code path you touched.
- If you add new commands/workflows, update this file.
