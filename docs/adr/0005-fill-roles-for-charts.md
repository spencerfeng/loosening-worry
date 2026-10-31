# 5. Two fill roles for charts and rings

Date: 2026-10-29

## Status

Accepted. Extends ADR 0001.

## Context

The Insights screen in the design canvas draws its top-trigger bars in amber `#F0A33A`, violet and green
`#4CB782`, and its habit ring in `#4CB782`, in light and dark alike. ADR 0001 collapsed these into the hue's
`Strong` role. The violet matches `violetStrong`, but `amberStrong` (`#B86E12`) and `greenStrong`
(`#2E8A5C`) are much darker, so the bars and the ring look heavier than the design.

The `Strong` roles can't simply get lighter. They also color text and icons on white and on the hue's
tint: the quick-tool icons, and at the time Nice catch's "+1" (now `greenOnTint`, ADR 0006). The design's brighter values wouldn't have enough contrast there.

## Decision

Add two roles to `Theme.ColorRole`, each pinned in the theme tests:

- `greenFill`: `#4CB782` in light and dark.
- `amberFill`: `#F0A33A` in light and dark.

They are for shapes that carry no text, such as chart bars, rings and progress fills. Text and icons keep
`Strong`. The canvas's dark Insights screen keeps the same values, so each fill is one color in both
appearances. Violet needs no fill role: the canvas uses `violetStrong` in light and dark.

## Consequences

- Insights' trigger bars and habit ring match the canvas.
- Breathe's circle and Nice catch's badge are `#4CB782` in the canvas too, but they still use
  `greenStrong`. Moving them to `greenFill` is a separate decision, because Nice catch's badge has a tick on
  it (`background` ink since ADR 0006) and Breathe's circle has words.
