# 1. Semantic colour tokens, collapsed from the design canvas

Date: 2026-10-22

## Status

Accepted

## Context

The app mockup lives in a Design canvas ("Loosening Worry — App Mockup",
https://claude.ai/artifact/81JjjCPB1YC34BeB6NVA7V). It has nine phone screens, each in light and dark.
The screens use raw hex values with no design system: 46 distinct light/dark colour pairs, including
five near-identical border greys and several one-off illustration fills.

## Decision

`Theme.swift` exposes 27 semantic colour roles, each with a light and a dark value taken from the
canvas. Examples: `background`, `surface`, `textPrimary`, `border`, `accent`, and a
strong / tint / on-tint colour for each tool hue.

- Near-duplicate canvas values merge into one role. The canvas shows what each colour is for, not the
  exact value to ship.
- One-off illustration colours (breathing halo, Be kind glow, curiosity rings) stay as private constants
  in the views that draw them. They are not Theme tokens.
- Dark mode ships in v1, using the canvas's dark screens.
- Hue families are named by colour (`green`, `amber`, `red`, `violet`), not by the tool that uses them.
  A hue may be reused outside its tool without being renamed. Each view maps its tool to a hue.
- **Help** has its own role, `help` (light `#C2453A`, dark `#F09A90`), separate from the `red` hue. It
  marks the crisis-support path and must not change when Be kind's hue is redesigned.
- Values live in `Assets.xcassets` as colour sets with Any and Dark appearances. `Theme.ColorRole` wraps
  Xcode's generated asset symbols, so role names are checked at compile time. Xcode handles switching
  between appearances, and Increase Contrast variants can be added later without code changes.

## Consequences

- Some elements differ from the mockup by 1–2% in lightness.
- New screens choose from named roles, not from hex values.
- A new colour in the canvas needs a decision: map it to an existing role, or add a role.
- Theme tests pin every role's light and dark hex values. Changing a colour on purpose means updating
  the asset catalog and the test table together. A colour that drifts by accident fails the tests.
