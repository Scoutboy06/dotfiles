# Quickshell Native Power Popout Design

## Goal

Replace the power button's Walker system menu with a native panel in the shared morphing popout host while preserving Omarchy's system actions.

## Layout

Use a single vertical action list:

1. Screensaver
2. Lock
3. Suspend, unless Omarchy's `suspend-off` toggle is enabled
4. Hibernate, only when supported
5. Logout
6. Restart
7. Shutdown

Each row has a Nerd Font icon, label, and themed hover state. Restart and Shutdown use the urgent color.

## Confirmation

Logout, Restart, and Shutdown switch the popout to an inline confirmation view with a warning, Cancel button, and urgent final-action button. Cancel returns to the list. Escape, outside-click, or morphing to another panel abandons confirmation.

Screensaver, Lock, Suspend, and Hibernate execute immediately. The popout closes before every action executes.

## Commands

- `omarchy-launch-screensaver force`
- `omarchy-system-lock`
- `systemctl suspend`
- `systemctl hibernate`
- `omarchy-system-logout`
- `omarchy-system-reboot`
- `omarchy-system-shutdown`

Using Omarchy's destructive-action helpers preserves graceful application shutdown behavior.

## Architecture

Add a shared `PowerService` for capability checks and command execution. Add persistent `PowerPopout` content to `PopoutHost`. Convert the existing power button to request the shared `power` panel and provide itself as the anchor.

Refresh suspend and hibernate availability periodically and when opening the panel. Reset confirmation whenever the power panel becomes inactive.

## Validation

Verify conditional Suspend and Hibernate rows, every immediate action where safe, confirmation cancellation, Escape and outside dismissal, hover morphing, anchor positioning, and clean logs. Validate destructive command wiring without executing Logout, Restart, or Shutdown during testing.
