# Loosening Worry — Context

Domain language for the app. The design source is the "Loosening Worry — App Mockup" canvas
(https://claude.ai/artifact/81JjjCPB1YC34BeB6NVA7V).

## Terms

- **Tool**: a short guided exercise someone can start any time worry shows up. Four exist: Get curious,
  Breathe, Note it and Be kind. Each tool is shown in one hue from the theme (see ADR 0001), but the
  hue is not the tool's identity.
- **Help**: the crisis-support path, reached from the Help button and the "Get help" link. It has its own
  colour role, kept separate from any tool's hue.
- **Check-in**: the daily notification, at a time the person picks during onboarding or in Settings. During the
  course it names the next lesson; after it, it invites them to log a loop. Code calls it the reminder
  (`ReminderSettings`, `ReminderScheduler`); the person only ever sees "check-in". It's kept on each device, since
  each device asks for its own notification permission.
- **Onboarding**: the five screens a device opens on until it has been through them once: what the app is for, what a
  loop is, how to use the app, what it isn't and where Help is, then the check-in time. Teaching is left to the
  lessons.
- **Option**: one choice in the logger for a loop's trigger, behavior or result. Triggers and behaviors are ranked
  by the person's history (see **Ranking**), six at a time with More for the rest. For results the logger shows the
  starters (the core results, in a fixed order) first, then the person's own in the order they were added, so step 3
  never nudges the answer. A logged loop keeps each answer's id, which history counts by, and its text as it was, so
  later changes to an option never rewrite past loops.
- **Starter**: an option that ships with the app, defined in code with a stable id (a `StarterID`, such as
  `trigger.news`) and a translated label. Starters are never stored, so a new or reworded starter reaches everyone
  with the next update. Once released, an id never changes: rewording changes only the label, because overrides
  are found by id and one under a changed id would be silently dropped. Before the first release ids were renamed
  freely.
- **Ranking**: the order of steps 1 and 2, worked out once when the step opens. The person's own options added in
  the last 7 days come first. Then triggers go by how often each was logged in the last 90 days; behaviors by how
  often each was logged with the trigger just picked, then by how often at all. Ties go to the person's own, then
  starter order. Loops under any id a choice shows count for it.
- **Starter pairs**: the behaviors offered first after each starter trigger (`starter-pairs.json`), until that
  trigger has three loops of the person's own in the last 90 days. A draft for the psychologist reviewer.
- **Override**: the person's change to a starter, stored under the starter's id. It hides or restores the starter;
  starters can't be renamed (to use other words, hide the starter and add your own). It keeps the starter's full
  text, so adding that text again brings the starter back. When devices disagree, the override edited last wins.
