# Caelestia-Inspired Quickshell Design

## Goal

Evolve the optional Quickshell panel into a small, smooth shell inspired by Caelestia while remaining compatible with Omarchy, multiple monitors, and future Omarchy Quickshell integration.

## Architecture

Keep an independent modular shell rather than forking Caelestia. Use one `Bar` instance for every screen exposed by `Quickshell.screens`. Separate workspace presentation, theme loading, and motion tokens into focused components.

```text
quickshell/
├── shell.qml
├── Bar.qml
├── components/
│   ├── WorkspaceList.qml
│   └── WorkspacePill.qml
├── services/
│   └── Theme.qml
└── theme/
    └── Motion.qml
```

No screen-edge border or border-dependent drawer architecture will be included.

## Theme synchronization

The theme service watches `~/.config/omarchy/current/theme/colors.toml`, including changes caused by switching the current theme. It exposes semantic colors such as background, foreground, accent, surface, and urgent. Components consume this interface rather than Omarchy files directly, allowing a future Omarchy API to replace the loader.

## Multi-monitor behavior

Every connected monitor receives a complete bar. Workspace indicators are filtered to the monitor represented by that bar. This supports the two-monitor desktop and single-monitor laptop from the same configuration.

## Motion

Central motion tokens adapt Caelestia's approach to reusable durations and expressive easing curves without importing its framework. Workspace pills animate size, position, state color, hover, and press feedback. Bars slide and fade in on launch and animate out before the toggle helper terminates Quickshell.

## Toggle behavior

`SUPER+SHIFT+Q` invokes a helper that guarantees at most one `qs` process. Starting launches the shell; stopping first requests its exit animation and then terminates it. Waybar remains unchanged and independently toggleable.

## Validation

- Validate shell script syntax and rendered chezmoi templates.
- Repeatedly toggle and confirm no duplicate `qs` processes.
- Change Omarchy themes and verify live color updates.
- Confirm each connected monitor receives exactly one complete bar with monitor-local workspaces.
- Reload and validate Hyprland after applying configuration.
- Preview all managed-file changes with `chezmoi diff` and avoid unrelated local changes.
