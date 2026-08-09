# Quickshell Notification Popout Design

## Goal

Move the existing Mako notification widget into the shared morphing popout host without changing its functionality.

## Behavior

- The bar button displays the active notification count.
- Clicking opens the notification popout beneath the button.
- Hovering the button while another shared popout is open morphs immediately to notifications.
- The active notification button remains highlighted while other bar hover feedback is suppressed.
- The popout shows up to six active notifications with summary and body text.
- Each notification can be dismissed individually.
- A “dismiss all” action appears when notifications exist.
- An empty-state message appears when none exist.
- Mako remains the notification daemon.

## Architecture

Add a shell-level `NotificationService` responsible for polling `makoctl list -j`, parsing active notifications, running dismissal commands, and refreshing after actions. All monitors consume the same service state.

Reduce `NotificationCenter` to a bar button that emits click and hover requests with itself as the anchor. Move the existing panel content into a persistent `NotificationPopout` registered with `PopoutHost`.

Remove the standalone notification `PanelWindow`. The shared host supplies positioning, monitor clamping, border, dismissal, crossfade, and geometry morphing.

## Refresh and Errors

Poll Mako every five seconds and refresh 150 ms after dismissal commands. Invalid or unavailable `makoctl` output produces an empty notification list rather than breaking the shell.

## Validation

- Verify count, empty state, and up to six active notifications.
- Verify individual and bulk dismissal.
- Verify click opening, outside-click and Escape dismissal.
- Morph between notifications and every existing native popout.
- Verify shared state and positioning on both monitors.
- Check Quickshell logs for warnings and errors.
