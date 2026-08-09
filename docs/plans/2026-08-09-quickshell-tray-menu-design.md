# Quickshell Tray Menu Design

## Goal

Refine system tray presentation and add themed right-click application menus while preserving normal tray activation.

## Power Icon

Change the power icon from the urgent color to the standard foreground color without changing its action or hover behavior. Commit this independently.

## Tray Icons

Keep each tray item's 24-pixel interaction target and reduce only the icon artwork from 16 to 14 pixels. Preserve current hover feedback and left-click activation.

## Tray Menus

Right-clicking an item with a DBus menu opens a dedicated themed popup beneath that icon. Only one tray menu is open at a time. Right-click falls back to `secondaryActivate()` when no menu is available.

The menu supports labels, icons, separators, disabled entries, checkbox and radio state, and nested submenus. Selecting a leaf action invokes it and closes the menu. Nested menus use in-place forward and back navigation to keep positioning predictable.

The popup uses Omarchy colors and font, rounded corners, a border, hover feedback, and shared motion timings. It is clamped to monitor margins and closes on outside click or Escape. It remains separate from the shared system popout host because application menus have independent nested navigation and interaction semantics.

## Validation

- Verify 14-pixel artwork with unchanged click targets.
- Verify left-click activation.
- Verify menu opening and fallback secondary activation.
- Verify separators, disabled actions, icons, checks, radio state, leaf actions, and nested navigation.
- Verify outside-click and Escape dismissal.
- Verify positioning near monitor edges and on each monitor.
- Check Quickshell logs for warnings and errors.
