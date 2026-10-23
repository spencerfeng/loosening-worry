# 3. The Log tab uses the system prominent tab, not a custom accent button

Date: 2026-10-24

## Status

Accepted

## Context

The mockup's Home screen ("Loosening Worry — App Mockup", https://claude.ai/artifact/81JjjCPB1YC34BeB6NVA7V)
shows the tab bar as a glass bar holding Home, Learn and Insights, with a separate round "Log a loop"
button beside it, filled with the accent colour.

iOS 27 draws that separate button natively: a `Tab` with `role: .prominent` in SwiftUI, backed by
`UITabBarController.prominentTabIdentifier`. On iOS 27.0 the system draws it as plain glass. Neither
framework offers a way to colour it: `TabContent` has no tint, background or style modifier, `.tint` on the
`TabView` colours only the selected tab, and `UITab` / `UITabBarController` expose no colour for the
prominent tab.

Matching the mockup exactly would mean dropping the prominent tab and placing a custom button next to the
system tab bar.

## Decision

The Log tab is a `Tab(role: .prominent)` and keeps the system's appearance. It is not filled with the accent.

Selecting it opens the Log sheet and leaves the current tab selected (`RootViewModel.select(_:)`), so Log
behaves as an action, not a destination.

## Consequences

- The Log button is glass, not accent blue. This is a known difference from the mockup, not a bug.
- The button adapts with the system for free: the side rail on iPhone Duo, the iPad sidebar, the tab bar
  minimising on scroll, and VoiceOver.
- If a later iOS release lets apps tint the prominent tab, apply the accent there and revisit this ADR.
- The mockup's accent fill should not be reproduced with a custom overlay without superseding this ADR.
