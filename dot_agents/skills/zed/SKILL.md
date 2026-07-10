---
name: zed
description: Use when working with Zed editor configuration, keybindings, settings, themes, or asking about Zed features.
---

# Zed Editor

## Documentation

Zed documentation is cloned to `~/.docs/zed/docs/src/`. Always start with
`SUMMARY.md` for the topic index, then read the relevant files.

Key reference files:
- `key-bindings.md` — keybinding syntax, contexts, disabling bindings (`null`), precedence
- `configuring-zed.md` — all settings and their options
- `all-actions.md` — full list of available actions for keybindings
- `reference/all-settings.md` — every setting with types and defaults

## Configuration

Dotfiles-managed config lives at `/home/elias/p/dotfiles/dot_config/zed/`:

| Source file | Live target |
|---|---|
| `dot_config/zed/keymap.json` | `~/.config/zed/keymap.json` |
| `dot_config/zed/private_settings.json` | `~/.config/zed/settings.json` |

The user uses `base_keymap: "VSCode"` and `vim_mode: true`.

## Keybinding Rules

- To disable a default binding, set the action to `null` in the appropriate
  context (usually `"Workspace"` for a global disable).
- `null` follows normal precedence: lower context nodes win, user keymap
  overrides defaults. Use `"Workspace"` context to disable everywhere.
- Example:
  ```json
  {
    "context": "Workspace",
    "bindings": {
      "ctrl-t": null
    }
  }
  ```
- Never use `unbind` (that's an old pre-0.197 format). Use `null` in `bindings`.