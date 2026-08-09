# Quickshell Media Popout Design

## Goal

Expand the existing compact MPRIS bar controls into a native media popout with artwork, metadata, seeking, transport controls, and multi-player selection.

## Layout

The panel contains:

1. Player identity in the heading, without a settings cog.
2. Album artwork beside track title, artist, and album.
3. Current position, seekable progress, and total duration.
4. Previous, play/pause, and next controls.
5. A player-selection section only when more than one MPRIS player exists.

Missing artwork uses a themed placeholder. Unsupported metadata fields collapse cleanly.

## Behavior

- Clicking the compact media area opens the popout centered beneath it.
- It participates in immediate hover morphing with Calendar, Network, Bluetooth, and Audio.
- The progress control is interactive only when the player supports seeking and reports a track length.
- Transport actions are hidden or disabled according to MPRIS capabilities.
- Selecting another player changes both the popout and compact bar controls.
- Selection does not start or stop a player.
- If the selected player disappears, the service chooses a playing player and then the first available player.
- With one player, the player-selection section is omitted.
- With no players, the compact media area and media panel request are unavailable.

## Architecture

Add a shared shell-level Media service that owns player selection and exposes the active MPRIS player to all monitors. Refactor the existing compact media controls to consume this service and emit click/hover requests with themselves as the popout anchor.

Register `MediaPopout` as another persistent panel in `PopoutHost`. Keep it instantiated so artwork and dimensions are ready before morphing.

## Styling and Motion

Use the Omarchy font, semantic colors, custom themed slider style, standard action buttons, card spacing, border, and shared motion tokens. Artwork has rounded corners. Player rows follow the established selected/hover row treatment.

## Validation

- Test one player and multiple simultaneous players.
- Verify player selection updates both bar and panel controls.
- Verify artwork and missing-artwork fallback.
- Test play, pause, previous, next, and seeking where supported.
- Verify duration formatting and live position updates.
- Close a selected player and verify fallback selection.
- Morph among all native panels on both monitors and check Quickshell logs.
