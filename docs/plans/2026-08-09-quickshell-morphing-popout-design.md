# Quickshell Morphing Popout Design

## Goal

Make native bar popouts behave like Caelestia's top-bar popouts: one persistent surface that immediately morphs and crossfades between widgets when the user hovers another popout-enabled icon.

## Interaction

- Clicking Audio or Bluetooth opens that panel or closes it when already active.
- While a panel is open, hovering another popout-enabled icon switches immediately.
- Hovering the active icon is a no-op.
- Hovering Wi-Fi, power, or other icons without native panels does nothing.
- Clicking outside or pressing Escape closes the popout.
- Only one monitor can own the active popout.

## Architecture

Replace the separate `AudioPopout` and `BluetoothPopout` windows with one monitor-local `PopoutHost`. Shared shell state records the active screen and panel name.

The host owns the window, background, border, positioning, dismissal, and transition animation. Audio and Bluetooth become content components hosted inside it. Both panels remain instantiated so their target dimensions are available before each transition and their state is preserved.

The host's fullscreen dismissal layer leaves the top-bar input region available so pointer hover events continue reaching the bar while a popout is open.

## Animation

The background and border remain continuously visible during panel changes. On switching:

1. The old panel fades out and shifts upward slightly.
2. The host animates its width and height toward the incoming panel's implicit size.
3. The new panel fades in and shifts into place.

Switching starts immediately on hover and completes in approximately 180–220 ms. Opening and closing retain the existing scale, opacity, and vertical motion. There is no bridge, collapse, or close/reopen transition.

## Extensibility

Future native Wi-Fi, media, calendar, and other panels only need a content component and a registered hover target. Window and transition behavior remain centralized in the host.

## Validation

- Open Audio and hover Bluetooth, then reverse the direction.
- Confirm the surface remains visible and morphs without flashes or geometry jumps.
- Confirm rapid repeated hovering resolves to the final hovered panel.
- Confirm hovering unsupported icons does nothing.
- Confirm outside-click and Escape dismissal still work.
- Test both monitors and ensure only one popout is active.
- Confirm clean Quickshell logs.
