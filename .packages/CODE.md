# CODE.md - .packages

## Purpose

Package definitions, read explicitly by the install scripts in
`.chezmoiscripts/` via `include ".packages/<file>" | fromYaml`.

This directory is deliberately NOT `.chezmoidata/`: chezmoi tries to parse
every file in `.chezmoidata/` as structured data and errors on anything else
(like this CODE.md). A plain dot-prefixed directory is ignored by chezmoi,
while `include` can still read files from it. Do not rename it back.

## Conventions

### Package files

- One file per package manager: `packages-<manager>.yaml` (pacman, aur, apt, bun, winget, etc.)
- `custom-arch-packages.yaml` is the exception: packages built from remote PKGBUILDs via makepkg, Arch only.
- Every package entry MUST have all three fields:
  - `name:` — the package name as known by that manager
  - `device:` — one of `all` | `eliaspc` | `eliaslt` | `worklt` | `server`
  - `requires_de:` — `true` if the package only makes sense with a desktop environment (filtered out on WSL/servers via `.hasDE`)
- Keep the explanatory header comment at the top of each file up to date if the schema changes.
