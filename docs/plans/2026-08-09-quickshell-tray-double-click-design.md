# Quickshell Tray Double-Click Design

## Behavior

A single left-click on a tray icon has no item-specific action. It passes through to the bar's background dismissal behavior, closing any open shared popout or tray menu.

A double left-click closes open popups and invokes the tray item's `activate()` action exactly once to open or focus its application.

Right-click continues to open the themed DBus context menu. Keeping left and right pointer handling separate prevents accidental activation while using application menus.

## Validation

Verify that single left-click dismisses an open menu without activating the application, double-click activates exactly once, and right-click still opens the context menu.
