# Quickshell Tray Focus Fallback Design

## Problem

Some tray applications, including Spotify, advertise the StatusNotifier `Activate` method but do not implement it. Double-clicking therefore cannot focus their existing window through the tray protocol alone.

## Design

On tray double-click, first invoke the standard tray `activate()` action so compliant applications can restore or activate themselves. After a short delay, call `omarchy-launch-or-focus` using the tray title as its window pattern.

Pass `true` as the launch command. This focuses an existing Hyprland window when one matches while safely doing nothing if no window exists, rather than guessing an application executable. The delay gives a compliant tray application time to restore its window before the focus fallback runs.

Single left-click and right-click menu behavior remain unchanged.

## Validation

Verify Spotify focuses on double-click. Verify a protocol-compliant tray application still activates normally, existing matching windows receive focus, no command is launched when no window matches, and single/right-click behavior remains intact.
