# Quickshell Popout Positioning Design

## Goal

Give every popout-capable bar component a geometry-independent way to request where the shared popout appears. The host centers beneath the requesting item, remains within monitor bounds, and animates between request positions.

## Request API

A component requests a popout using a panel identifier and its visual anchor item:

```qml
requestPopout("audio", audioButton)
```

The bar controller maps the anchor item's horizontal center into monitor-local coordinates. Components do not calculate screen positions and do not know the popout's dimensions.

Shared shell state stores the active screen, active panel identifier, and requested horizontal center.

## Host Positioning

The host derives its desired left coordinate from:

```text
requested center - popout width / 2
```

It clamps the result between consistent monitor margins:

```text
left margin <= popout left <= screen width - popout width - right margin
```

This centers ordinary items beneath their popout while keeping items near either edge fully visible. Coordinates remain local to each monitor's full-width bar window.

The vertical position remains immediately beneath the top bar.

## Animation

When switching between panels, the persistent surface simultaneously:

- slides horizontally toward the new anchor;
- morphs to the incoming panel dimensions;
- crossfades and subtly shifts its content.

Position, dimensions, and content use the shared approximately 200 ms motion timing. Opening starts at the requesting item's clamped position.

## Extensibility

A future bar component only provides:

1. its panel identifier;
2. its anchor item;
3. its hosted content component.

The shared bar controller and popout host own coordinate mapping, monitor bounds, margins, dismissal, and animation.

## Validation

- Confirm Audio and Bluetooth center beneath their respective icons.
- Switch repeatedly and verify smooth horizontal movement with the existing morph.
- Resize panels and verify their center remains aligned where monitor bounds permit.
- Request positions near both monitor edges and verify the card remains visible.
- Test each monitor independently and check Quickshell logs.
