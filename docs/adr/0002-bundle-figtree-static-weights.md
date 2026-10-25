# 2. Bundle Figtree as four static weights

Date: 2026-10-22

## Status

Accepted

## Context

The design canvas sets all text in Figtree, an open-source sans-serif released under the SIL Open Font
License. iOS does not include it, so the app must bundle it. The mockups use weights 400, 600, 700 and
800. They never use 500, although the stylesheet loads it.

## Decision

Bundle four static TTFs from the Google Fonts release: `Figtree-Regular`, `Figtree-SemiBold`,
`Figtree-Bold` and `Figtree-ExtraBold`. Ship `OFL.txt` with them. Each Theme text style refers to its
face by exact PostScript name. We do not use the variable font.

Every text style scales with Dynamic Type. It is declared with `Font.custom(_:size:relativeTo:)`, using
the mockup size as the default and the closest system text style as the scaling reference.

Styles take Apple's text style names. Each one scales relative to the system style of the same name:

| Style | Size / weight | Use |
|---|---|---|
| `largeTitle` | 48 / ExtraBold | Stat numerals |
| `title` | 28 / ExtraBold | Screen titles |
| `title2` | 24 / ExtraBold | A number read at a glance, like the anxiety level |
| `title3` | 20 / Bold | Section headings |
| `headline` | 17 / Bold | Primary button labels |
| `body` | 16 / Regular | Paragraphs |
| `callout` | 15 / Bold | Links, secondary buttons |
| `subheadline` | 14 / Bold | Chips, tile labels |
| `footnote` | 13 / SemiBold | Metadata |
| `caption` | 13 / Regular | Notes under a field |
| `caption2` | 11 / SemiBold | Tab-bar labels |

## Consequences

- Each rendered weight is exactly the one the mockup specifies. SwiftUI's handling of weight axes on
  variable custom fonts doesn't come into it.
- A unit test can check that every face Theme names actually resolves.
- Adding a weight later means adding a file.
- Costs about 200 KB more than the variable font.
