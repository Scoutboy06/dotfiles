# Quickshell Hyprland Bar Animation Design

## Goal

Make whole-bar entrance and exit animation match Hyprland's effective layer animation settings.

## Source

Query `hyprctl animations -j` at startup. Read the effective `layersIn` and `layersOut` entries and resolve their named Bézier curves against the curve definitions returned in the same response.

Convert Hyprland animation speed units to milliseconds using `speed × 100`. Refresh on Hyprland's `configreloaded` IPC event. If parsing fails, use the current Omarchy defaults:

- In: 400 ms, `(0.23, 1, 0.32, 1)`
- Out: 150 ms, linear

When Hyprland animations are disabled, use immediate transitions.

## Architecture

Add one shell-level `HyprAnimationService` exposing layer-in and layer-out durations and Bézier arrays. Share it with every monitor bar.

Use layer-in timing for initial reveal and returning from fullscreen. Use layer-out timing for fullscreen hiding and shell exit. Apply the same directional timing to vertical position and opacity.

Internal control, hover, and popout animations continue using the existing Quickshell motion tokens.

## Validation

Compare startup reveal, fullscreen hide, and fullscreen restore against Hyprland layer windows. Change layer animation speed or curve temporarily, reload Hyprland, and verify the bar follows without restarting Quickshell. Restore configuration and check logs.
