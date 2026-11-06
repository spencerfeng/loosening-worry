# 7. Three fill roles for Insights' "What sets you off"

Date: 2026-11-06

## Status

Accepted. Extends ADR 0001 and ADR 0005. `accentPaleFill` was removed on 2026-11-06, when the logger's "When did you
notice?" went from three answers to two and "partway" went with it. Nice catch's "last times" dots also use `redFill`
and `grayFill`, beside `greenFill`, under the same rule: shapes that carry no text.

## Context

Insights' "What sets you off" card and each trigger's page draw a bar of what followed a trigger: the old habit in
red, a tool to meet the urge in green. The page also shows when the person noticed each habit as a row of dots: gray
for afterwards, pale blue for partway, blue for as it started.

The canvas draws the red as `#D9574B` in light and `#F09A90` in dark, the gray as `#C9C5BE` / `#6B6862`, and the pale
blue as `#C9D9FA` / `#2C4170`. No fill role has these values. `redStrong` matches the light red but stays `#D9574B` in
dark, and like every `Strong` role it is meant for text and icons (ADR 0005). The gray and the pale blue match no role
for shapes: `accentBorder` has the pale blue's values, but it outlines rows.

## Decision

Add three roles to `Theme.ColorRole`, each pinned in the theme tests:

- `redFill`: `#D9574B` in light, `#F09A90` in dark.
- `grayFill`: `#C9C5BE` in light, `#6B6862` in dark.
- `accentPaleFill`: `#C9D9FA` in light, `#2C4170` in dark.

Like `greenFill` and `amberFill`, they are for shapes that carry no text: bars, dots and their keys' swatches. The
noticing dots' "as it started" is `accent`, which needs no new role.

## Consequences

- The habit's share of a bar sits beside `greenFill` at the same weight, as in the canvas.
- `grayFill` and `accentPaleFill` are pale in light mode, so they never carry text or stand alone as the only cue: the
  card says what the dots show in words too.
