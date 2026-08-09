# Quickshell Fullscreen Bar Design

## Goal

Hide the Quickshell bar like Waybar when an application is fullscreen, independently for each monitor.

## State

Use Quickshell's reactive Hyprland model:

```text
Hyprland.monitorFor(screen).activeWorkspace.hasFullscreen
```

Hyprland emits IPC changes and Quickshell updates this property without polling.

## Behavior

When the active workspace on a bar's monitor contains a fullscreen window:

- Slide and fade that bar upward.
- Set its exclusive zone to zero so the fullscreen client can use the complete monitor.
- Clear the bar window's input region so it cannot intercept fullscreen clicks.
- Dismiss shared and tray popups associated with that monitor.

When fullscreen ends or the monitor switches to a non-fullscreen workspace, restore the 36-pixel exclusive zone and animate the bar into view. Other monitors remain unaffected.

## Validation

Fullscreen and unfullscreen clients on each monitor independently. Switch between fullscreen and normal workspaces. Verify complete client geometry, restored tiling geometry, popup dismissal, no invisible input interception, animation, and clean logs.
