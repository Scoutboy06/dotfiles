# Quickshell Bluetooth Popout Design

## Goal

Replace the Bluetooth icon's launcher-only behavior with a native popout for managing known devices while retaining a shortcut to full Omarchy Bluetooth settings.

## Scope

The first version supports the default Bluetooth adapter and known paired devices only. Discovery, pairing, and forgetting devices remain in the full settings application.

## Architecture

Use `Quickshell.Bluetooth` directly for reactive adapter and device state. A shared shell-level service exposes the default adapter, enabled state, and paired devices to all bars. Reuse the existing animated `PopoutLayer` so outside-click dismissal, Escape handling, monitor-local positioning, and theme styling remain consistent with audio.

## Layout

The right-aligned card contains:

1. Bluetooth heading, settings cog, and enabled toggle.
2. Connected devices section, including battery percentage where available and a disconnect action.
3. Paired devices section with connect actions.
4. An empty-state message when no known devices exist.

## Behavior

- Clicking the Bluetooth bar icon toggles the popout.
- Adapter state updates natively and the heading toggle powers Bluetooth on or off.
- Device rows show connecting/disconnecting state while transitions are in progress.
- Connected devices sort before disconnected devices.
- Clicking a row action connects or disconnects that device.
- The cog launches `omarchy launch bluetooth`.
- Opening Bluetooth closes any open audio popout, and vice versa.
- Only one monitor's Bluetooth popout can be open.

## Styling

Use the Omarchy font and semantic colors, the same border and spacing as the audio popout, highlighted connected rows, subtle hover transitions, and shared motion tokens.

## Validation

Test adapter toggling, connection and disconnection for the WH-1000XM4 and Xbox Wireless Controller, battery display where available, cross-popout exclusivity, both monitors, outside-click and Escape dismissal, and clean Quickshell logs.
