# Loosening Worry — Context

Domain language for the app. The design source is the "Loosening Worry — App Mockup" canvas
(https://claude.ai/artifact/81JjjCPB1YC34BeB6NVA7V).

## Terms

- **Tool**: a short guided exercise someone can start any time worry shows up. Four exist: Get curious,
  Breathe, Note it and Be kind. Each tool is shown in one hue from the theme (see ADR 0001), but the
  hue is not the tool's identity.
- **Help**: the crisis-support path, reached from the Help button and the "Get help" link. It has its own
  colour role, kept separate from any tool's hue.
- **Option**: one choice in the logger for a loop's trigger, behavior or result. For triggers and behaviors the
  logger shows the person's own options first, newest first, then the starters. For results it shows the starters
  (the core results, in a fixed order) first, then the person's own in the order they were added, so step 3 never
  nudges the answer. A logged loop keeps the option's text as it was, so later changes to an
  option never rewrite past loops.
- **Starter**: an option that ships with the app, defined in code with a stable id (such as `trigger.news`) and
  a translated label. Starters are never stored, so a new or reworded starter reaches everyone with the next
  update. Once released, an id never changes: rewording changes only the label, because overrides are found by
  id and one under a changed id would be silently dropped. Before the first release ids were renamed freely.
- **Override**: the person's change to a starter, stored under the starter's id: a new label renames it and
  hiding removes it. When devices disagree, the override edited last wins.
