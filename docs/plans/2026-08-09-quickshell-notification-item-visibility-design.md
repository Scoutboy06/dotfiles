# Quickshell Notification Item Visibility Design

Hide the notification bar item when there are no active notifications. Its containing row should remove it entirely so the right island contracts without leaving padding or spacing.

When a notification arrives, show the item automatically with the shared active count on every monitor.

If the final notification disappears while the notification popout is active, close that popout automatically and clear its shared popup state. Other active popouts remain unaffected.

Validate appearance and disappearance, right-island resizing, multi-monitor synchronization, individual and bulk dismissal, automatic close after the final dismissal, and clean logs.
