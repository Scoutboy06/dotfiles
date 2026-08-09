# Quickshell Bar Dismissal and Compact Tray Menu Design

## Goal

Dismiss open popups consistently when interacting with the bar and make tray application menus more compact and correctly aligned.

## Bar Dismissal

Clicking empty bar space closes both the shared system popout and tray menu. Clicking an unrelated bar control closes the current popup before performing that control's normal action.

Popout-capable controls retain their existing behavior: they open or switch to their panel, close any tray menu, and toggle closed when clicked while already active. Repeated right-clicks on the tray icon whose menu is already open leave that menu unchanged. Another tray icon replaces or closes the current menu according to its normal action.

Centralize dismissal in the bar where possible and add explicit dismissal only to controls whose pointer handlers consume the event.

## Compact Tray Menu

Use a roughly 224-pixel card width, 6-pixel card margins, 26-pixel action rows, and 6-pixel internal horizontal padding. Explicitly center icons, check and radio indicators, labels, and submenu arrows vertically within each row.

Preserve separators, disabled styling, nested navigation, edge clamping, and menu actions.

## Validation

Verify dismissal from empty bar space and unrelated launcher, workspace, tray, battery, and system controls. Verify popout switching and existing tray-menu repeated-click behavior. Inspect labels, icons, state markers, and arrows across several tray menu entries and nested pages. Check logs for warnings and errors.
