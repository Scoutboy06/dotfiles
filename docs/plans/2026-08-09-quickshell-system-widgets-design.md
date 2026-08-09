# Quickshell System Widgets Design

## Goal

Expand the animated Quickshell bar with useful system controls inspired by Caelestia while retaining Omarchy's existing applications and services.

## Layout

Each monitor receives the same complete horizontal layout:

```text
[Arch] [workspaces]       [media | clock]       [tray] [notifications] [battery] [wifi] [bluetooth] [audio] [power]
```

The active window title is intentionally omitted.

## Architecture

Use Quickshell's native services for responsive state and Omarchy commands for initial control surfaces. Each control remains an isolated component so an Omarchy command can later be replaced with a native animated popout without changing the bar layout.

All widgets consume the existing Omarchy theme adapter and shared motion tokens.

## Components

- **Arch logo:** launch the Omarchy application picker through `omarchy-launch-walker`.
- **System tray:** use Quickshell's `SystemTray` service. Activate items on left-click and expose native item menus on right-click.
- **Wi-Fi:** display connectivity state and launch `omarchy launch wifi`.
- **Bluetooth:** display enabled and connected state and launch `omarchy launch bluetooth`.
- **Audio:** display volume and mute state, launch `omarchy launch audio`, and adjust volume on scroll.
- **Power:** open Omarchy's system menu.
- **Battery:** render only when a battery exists and show percentage, charging state, and a warning color at low charge.
- **Media:** use MPRIS, prefer a currently playing source, and expose previous, play/pause, and next actions.
- **Notifications:** retain Mako. Show active/history count and provide an animated drawer based on `makoctl list -j` and `makoctl history -j`, with restore and dismiss actions.
- **Clock:** remain centered beside media information.

## Evolution

Wi-Fi, Bluetooth, audio, and power initially launch Omarchy controls. They can be replaced incrementally by native Quickshell popouts. Mako remains the notification daemon; Quickshell only presents its state and history.

## Validation

- Launch with no tray items, battery, media player, or notifications.
- Validate tray activation and menus.
- Verify battery visibility on desktop and laptop.
- Verify MPRIS controls and player selection.
- Verify Mako counts, restore, and dismiss behavior.
- Verify Omarchy launch commands and volume scrolling.
- Confirm every monitor receives one bar and no duplicate services or shell processes are created.
