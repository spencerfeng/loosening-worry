# 6. Contrast fixes for small text on fills

Date: 2026-10-31

## Status

Accepted. Extends ADR 0001.

## Context

An accessibility pass measured every text color against what it sits on, by WCAG 2: 4.5:1 for text under
18pt (14pt bold), 3:1 for larger text and icons. Most roles pass in both appearances. Three kinds of pair didn't:

- Small white text on `accent` in dark mode. The canvas's dark `accent`, `#4C82F0`, gives white 3.65:1.
  Home's Log banner line ("Log trigger, behavior, result in 20 sec") and the picked check-in card's time are
  13pt. Darkening `accent` itself isn't an option: it also tints the selected tab's label, switches and strokes
  on the dark page, where `#4C82F0` is what keeps them readable (5.05:1 on `background`).
- White on `greenStrong` in dark mode, where the green is light (`#5CC48F`): 2.15:1, under even the 3:1 for
  Breathe's large phase words and Nice catch's tick.
- Small text in a `Strong` hue: Nice catch's "+1" (`greenStrong` on `greenTint`, 3.75:1 in light) and Log a
  loop's "couldn't save" line (`redStrong` on the page, 3.88:1).

## Decision

- Add `accentFill`, `#2E6AE6` in light and dark, for accent fills that carry small white text. White on it is
  4.86:1. `accent` keeps the canvas's values for everything else, so this is the one role that departs from
  the canvas's dark screens.
- Text and icons on a `Strong` fill that is light in dark mode take `background` as their ink, as Help's call
  button already does. That is `#F7F6F3` in light (3.96:1 on `greenStrong`) and `#141413` in dark (8.56:1).
  No new role: it would hold the same values as `background`.
- Small text in a hue takes its `OnTint` role, also when it sits on the page rather than on the tint, as the
  `OnTint` values are dark enough for both. `Strong` stays for icons and large text.

## Consequences

- Home's banner and the picked check-in card are a shade darker than the canvas in dark mode.
- Breathe's phase words and Nice catch's tick are off-white in light mode rather than white.
- A new fill with small text on it starts from `accentFill`, or checks its contrast in both appearances.
