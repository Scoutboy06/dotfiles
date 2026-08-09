# Quickshell Bootstrap Design

## Goal

Add a small, optional Quickshell panel for experimenting under Hyprland without changing Waybar or compositor startup.

## Design

- Manage Quickshell as a desktop package through the repository's Arch package definitions.
- Add a modular `~/.config/quickshell` configuration with a top panel containing Hyprland workspace indicators, a centered clock, and basic network and battery placeholders.
- Add a `~/.local/bin/toggle-quickshell` helper that starts Quickshell when absent and stops it when running.
- Bind `SUPER+SHIFT+Q` to the helper. The binding is currently unused.
- Do not autostart Quickshell or alter Waybar. Both bars remain independently controllable.

## Validation

- Format-check shell scripts with `bash -n`.
- Render and inspect changes with `chezmoi diff` before applying.
- Launch Quickshell manually through the toggle after the package is installed.
