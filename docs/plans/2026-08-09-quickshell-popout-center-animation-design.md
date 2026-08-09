# Quickshell Popout Center Animation Design

## Problem

The shared popout animates `x` while `x` depends on its simultaneously animated width. Each width frame changes the horizontal target and retargets the `x` animation, causing visible positional lag.

## Design

Animate a dedicated horizontal center coordinate instead of the card's left edge. Derive the card's `x` from the animated center and current animated width, then clamp the result to the monitor margins.

When morphing between open panels, the center animation begins immediately and uses the same shared spatial timing as size morphing. Width changes no longer restart horizontal motion.

When opening from closed state, set the animated center directly to the requested center so the card appears at final geometry without an initial horizontal slide. Preserve existing monitor clamping and close behavior.

## Validation

Morph between popouts with substantially different widths and anchors on both sides of the bar. Verify that horizontal movement starts immediately, remains centered during size changes, finishes with the size animation, and stays within monitor margins. Verify direct positioning when opening from closed state.
