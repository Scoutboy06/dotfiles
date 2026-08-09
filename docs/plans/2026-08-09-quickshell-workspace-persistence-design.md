# Quickshell Persistent and Special Workspaces Design

## Numeric Workspaces

Every monitor bar always shows global numeric workspaces 1 through 5, including workspaces that Hyprland has not created yet. Activating a numeric pill uses normal global workspace activation, focusing the monitor that currently owns that workspace.

## Special Workspaces

After the numeric pills, show each special workspace that either contains a window or is currently focused. Populated hidden specials remain visible. A focused empty special remains visible until it loses focus.

All bars show the same global populated-special list. Sort special workspaces alphabetically and display their names without the `special:` prefix. Clicking one dispatches `togglespecialworkspace` for that name.

## Appearance

Retain the existing compact and expanded accent treatment. Numeric pills keep their existing dimensions. Named special pills expand to fit their labels. The focused special receives active styling; hidden populated specials remain compact.

## Validation

Verify 1–5 remain present when empty, global activation focuses the owning monitor, nonexistent workspaces can be created, hidden populated specials remain present, empty unfocused specials disappear, focused empty specials remain, toggling works from either monitor, ordering remains stable, and logs are clean.
