# Loosening Worry — Context

Domain language for the app. The design source is the "Loosening Worry — App Mockup" canvas
(https://claude.ai/artifact/81JjjCPB1YC34BeB6NVA7V).

## Terms

- **Tool**: a short guided exercise someone can start any time worry shows up. Four exist: Get curious,
  Breathe, Note it and Be kind. Each tool is shown in one hue from the theme (see ADR 0001), but the
  hue is not the tool's identity.
- **Check-in**: a short record of how the person feels right now, started from the Check in row on Home (under "For
  you today", above the lesson) or from the reminder after the course. Three steps: how it feels overall, on Apple's
  seven-step State of Mind scale from very unpleasant to very pleasant; then, optionally, any of HealthKit's 38 State
  of Mind labels that describe it, with the ones that match the first answer listed first and the rest behind More;
  then, optionally, any **check-in contexts**. Going back clears what was picked on the step left; the step returned
  to keeps its answer. The labels are fixed: unlike options, they can't be added to, hidden or reworded. It can be
  done any number of times a day; Home shows today's count and the time of the last one. It never leads to the lesson.
  When the feeling is on the unpleasant side, the finish screen suggests a tool chosen from the words picked (worry
  words to Get curious, self-judgment to Be kind, heated words to Note it, drained to Breathe), with the other tools
  and Log a loop beside it. Insights has a Check-ins side, beside Loops: how the check-ins felt (a mix, never a score
  or trend), the five words named most, and the contexts picked most on unpleasant and on pleasant check-ins. It waits
  for five check-ins in the period.
- **Check-in context**: what's having the biggest impact on the person, the check-in's last step. Contexts are options
  of their own kind (`OptionKind.context`). The starters are HealthKit's 18 State of Mind associations (Community,
  Current events, … Work); the person's own sit among them, all listed alphabetically, and one just added, in the step
  or on the Edit screen, is picked. Text left typed in the field when the person taps Done is added too. The person
  adds their own in the step, kept for next time, and removes or restores any, starters included, on the Edit screen,
  which shows only contexts when opened from the check-in. A check-in keeps each context's id and its text as it was,
  like a loop.
- **Reminder**: the daily notification, at a time the person picks during onboarding or in Settings
  (`ReminderSettings`, `ReminderScheduler`). During the course it names the next lesson; once every lesson is done it
  asks "How are you right now?" and opens the check-in. It's kept on each device, since each device asks for its own
  notification permission.
- **Lock**: the optional cover that asks for Face ID, Touch ID, Optic ID or the passcode, whichever the device uses,
  before the app shows anything. It asks when the app opens and when it comes back after more than a minute away (the
  grace minute, `AppLockViewModel.grace`). While the app is away it shows only the icon, so the app switcher shows
  nothing private. It's kept on each device, and turns itself off if the device's passcode is removed.
- **Onboarding**: the five screens a device opens on until it has been through them once: what the app is for, what a
  loop is, how to use the app, what it isn't, then the reminder time. Teaching is left to the lessons.
- **Option**: one choice in the logger for a loop's trigger, behavior or result. Triggers and behaviors are ranked by
  the person's history (see **Ranking**), six at a time with More for the rest. For results the logger shows the
  starters (the core results, in a fixed order) first, then the person's own in the order they were added, so step 3
  never nudges the answer. A logged loop keeps each answer's id, which history counts by, and its text as it was, so
  later changes to an option never rewrite past loops. Removing one of the person's own hides it, keeping its id, so
  restoring it or typing its text again brings back the same history. From the Removed list they can also delete their
  own for good (starters can only be hidden). What was logged with it keeps its text, and adding that text again later
  brings the option back under its old ids, so its history counts with it again.
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
