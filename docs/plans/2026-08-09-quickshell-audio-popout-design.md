# Quickshell Audio Popout Design

## Goal

Replace the audio icon's Omarchy launcher-only behavior with a compact native PipeWire popout while retaining access to Omarchy's full audio controls.

## Architecture

Use Quickshell's PipeWire service for reactive audio state and direct controls. Add one shared audio service at shell scope to track default input/output nodes and physical sinks/sources. Bars consume the shared service rather than polling separately per monitor.

Extract popout positioning, outside-click dismissal, and motion into a reusable component suitable for future Wi-Fi, Bluetooth, calendar, and media popouts.

## Layout

The popout is a vertical card approximately 320px wide, aligned under the audio icon and constrained to its monitor:

1. Audio heading and settings action.
2. Output device name, percentage, mute control, and volume slider.
3. Available output devices with the active device highlighted.
4. Divider.
5. Microphone device name, percentage, mute control, and input slider.
6. Button to launch `omarchy launch audio`.

## Behavior

- Clicking the bar audio icon toggles the popout.
- Clicking outside or pressing Escape closes it.
- Opening and closing animate opacity, vertical offset, and scale.
- Speaker and microphone icons toggle mute.
- Sliders update continuously while dragging and preserve their position when muted.
- Output selection updates PipeWire's preferred default sink.
- The existing mouse-wheel volume adjustment remains available.
- Only one monitor's audio popout is open at a time.

## Styling

Use semantic colors from the Omarchy theme adapter and durations/easing from the shared motion tokens. Device rows receive subtle hover and selection transitions. No Caelestia components are copied.

## Validation

- Test volume and mute synchronization with external controls.
- Select each available output and verify PipeWire's default sink.
- Test microphone volume and mute.
- Verify opening, closing, outside-click, and Escape behavior on both monitors.
- Verify the popout stays inside each monitor.
- Confirm only one PipeWire tracker/service exists and Quickshell logs no warnings.
