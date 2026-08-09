# Quickshell Calendar Popout Design

## Goal

Add a native date and month calendar anchored beneath the center clock and integrated into the shared morphing popout host.

## Layout

The panel contains:

1. The full current date as a heading.
2. A month heading with previous and next controls.
3. Locale-aware weekday labels.
4. A six-week month grid.
5. A Today action that returns to the current month.

Today uses an accent-filled pill. Dates outside the displayed month remain visible but dimmed so each month keeps stable geometry.

## Behavior

- Clicking the center clock opens or closes the calendar beneath it.
- Hovering the clock while another native panel is open morphs to the calendar immediately.
- Hovering Audio, Bluetooth, or Network morphs away from it.
- Previous and next controls navigate one month at a time.
- Today returns to the current month.
- Ordinary date cells have no action in the initial version.
- The displayed month remains preserved while another panel is active.
- Outside-click and Escape dismissal continue to use the shared host.

## Architecture

Turn the clock display into a reusable bar button that emits click and hover requests with itself as the anchor. It retains the active visual state while the rest of the bar's hover feedback is locked.

Register `CalendarPopout` as a fourth persistent panel in `PopoutHost`. Use Qt's native month grid and day-of-week model with themed delegates, avoiding custom date arithmetic and external `cal` parsing.

## Styling and Motion

Use the Omarchy font, semantic colors, spacing, border, and motion tokens. Keep the calendar width consistent with the existing 340px cards. Month navigation uses the standard action button. The host handles horizontal movement, size morphing, and content crossfade.

## Validation

- Open the calendar from the clock and verify anchor centering.
- Navigate across year boundaries in both directions.
- Verify the correct today cell and current-month styling.
- Use Today after navigating away.
- Morph among Calendar, Network, Bluetooth, and Audio.
- Confirm month state survives a morph.
- Test both monitors, outside-click, Escape, and clean Quickshell logs.
