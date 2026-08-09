# Quickshell Hook-Driven Theme Design

## Goal

Use Omarchy's theme-change hook instead of filesystem watching to reload Quickshell colors, including Waybar-specific overrides.

## Theme Sources

Read `colors.toml` as the complete base palette. Read `waybar.css` afterward and let matching `@define-color` entries override the base palette, especially `background` and `foreground`.

Support direct hex values, color aliases, and `alpha()` expressions. Preserve base colors for semantic values not defined by Waybar.

## Reload Flow

Add a `reloadTheme()` method to Quickshell's existing `shell` IPC handler. It explicitly reloads both theme files.

Manage `~/.config/omarchy/hooks/theme-set` through chezmoi. Preserve its existing Omazed block and append a silent IPC call:

```bash
qs ipc call shell reloadTheme >/dev/null 2>&1 || true
```

If Quickshell is not running, the hook continues normally. Quickshell reads the current files on its next startup.

Remove filesystem `watchChanges` usage. Manual edits do not update until the theme is reapplied or Quickshell restarts.

## Validation

Verify Elias Jade uses Waybar's black background instead of the TOML background. Switch between themes and confirm one hook-driven live update per switch. Verify Omazed still runs, aliases and alpha colors parse, startup loads correctly, and logs remain clean.
