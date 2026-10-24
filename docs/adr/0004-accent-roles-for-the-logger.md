# 4. Four more accent roles for the logger's states

Date: 2026-10-24

## Status

Accepted. Extends ADR 0001.

## Context

The Log a loop screen in the design canvas uses four accent colors that none of ADR 0001's 27 roles
hold:

- the light end of the progress segments' gradient (`#5B8DF0`, dark `#6E99F3`)
- the current summary row's fill (`#F1F5FE`, dark `#1A2540`)
- the current summary row's 1.5pt outline (`#C9D9FA`, dark `#2C4170`)
- the blue of the soft shadows under the tick, the cheer, the selected chip and the Save button
  (`#2E6AE6` at 14–35% opacity, the same in dark mode)

ADR 0001 merges near-duplicates. The row fill sits close to `accentTint` (`#E4EDFD`), but the screen
uses both at once: `accentTint` outlines the cheer badge directly below the paler row, so merging them
would lose a difference the design draws on purpose. The other three have no near match.

## Decision

Add four roles to `Theme.ColorRole`, each pinned in the theme tests:

- `accentSoft`: the lighter end of accent gradients.
- `accentWash`: the fill of the current row in a list, paler than `accentTint`.
- `accentBorder`: the outline of that row.
- `accentShadow`: the shadow tint under accent elements. It stays `#2E6AE6` in dark mode, as the
  canvas does, and views apply the opacity.

They are roles, not private constants, because the shadow already repeats across elements, and the
current-row and gradient treatments will reappear in other lists and progress displays.

## Consequences

- `Theme.swift` now has 31 color roles.
