# Quickshell Dynamic Bar Spacing Design

## Goal

Keep the visible gap above the Quickshell bar equal to the gap between the bar and tiled windows while following live Omarchy/Hyprland appearance settings.

## Source of Truth

Query Hyprland's live IPC options rather than parsing Omarchy configuration files:

- `general:gaps_out`
- `general:border_size`

The visible spacing Hyprland adds below a reserved layer surface is the top outer gap plus the tiled-window border size. Use that same value above the bar.

## Geometry

Calculate:

```text
barMargin = topGapOut + borderSize
barY = barMargin
exclusiveZone = barHeight + barMargin
```

Hyprland adds its normal gap and border below the exclusive zone, producing matching visible spacing above and below the bar.

## Architecture

Add one shell-level bar layout service that queries the options at startup and refreshes on Hyprland's `configreloaded` event. Share the calculated margin with every monitor bar. Use a 10-pixel fallback if IPC output is unavailable or invalid.

## Validation

Verify current 8-pixel outer gaps and 2-pixel borders produce a 10-pixel margin. Compare the visible top and bottom spaces on both monitors. Change gap or border settings temporarily through Hyprland IPC, reload configuration, and confirm geometry updates. Check logs for warnings and restore the original settings.
