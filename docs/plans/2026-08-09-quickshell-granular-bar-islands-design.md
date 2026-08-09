# Quickshell Granular Bar Islands Design

## Goal

Split the center and right bar groups into more focused background islands while preserving alignment and dynamic content behavior.

## Layout

Use five logical islands:

1. Launcher and workspaces
2. Media controls
3. Clock
4. System tray
5. Notifications, battery, network, Bluetooth, audio, and power

The center uses a transparent centered row containing the media and clock islands with a 6-pixel gap. The right uses a transparent right-aligned row containing the tray and status islands with a 6-pixel gap.

Each island retains its 32-pixel height, 10-pixel radius, 6-pixel horizontal padding, theme background, and color animation.

## Dynamic Visibility

Hide the media island when no playable MPRIS player exists. Hide the tray island when no tray items exist. Hidden islands have zero width, and the containing row removes their adjacent spacing automatically, leaving no empty background or stray gap.

## Validation

Verify all five islands with active media and tray items. Test no media, an empty tray, and both empty. Confirm the clock stays centered, the status island remains right-aligned, and gaps appear only between visible islands. Verify popup anchors, dismissal, reveal animation, and logs.
