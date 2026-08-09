# Quickshell Bar Islands Design

## Goal

Replace the full-width top-bar background with three independently sized background islands for the left, center, and right control groups.

## Layout

Keep one transparent full-width layer-shell window and exclusive zone. Inside it, use a transparent animated container holding three 32-pixel-high rounded rectangles:

- Left: launcher and workspaces
- Center: media controls and clock
- Right: tray, notifications, battery, system status, and power

Each island tightly wraps its row's implicit width with 6 pixels of padding on each side. Islands retain the current 10-pixel radius, theme background color, and color animation.

## Behavior

All islands share the existing slide-in and fade reveal animation. Dynamic content changes resize only the affected island. The full-width transparent container remains available for popup anchor coordinate mapping and empty-space dismissal.

Preserve one exclusive zone, multi-monitor behavior, popout positioning, hover suppression, and all existing interactions.

## Validation

Verify tight wrapping with and without media, tray items, notifications, and battery. Check left, centered, and right alignment on each monitor. Verify reveal animation, theme updates, empty-space dismissal, and every popout anchor. Check Quickshell logs for warnings and errors.
