import Foundation

/// The stretch of time Insights looks at.
enum InsightsPeriod: CaseIterable {
    /// The person's calendar week so far, a bar per day.
    case thisWeek
    /// This week and the three before it, a bar per week, to show whether loops are getting rarer.
    case lastFourWeeks

    /// What one bar of the chart covers.
    var unit: Calendar.Component {
        switch self {
        case .thisWeek: .day
        case .lastFourWeeks: .weekOfYear
        }
    }

    var barCount: Int {
        switch self {
        case .thisWeek: 7
        case .lastFourWeeks: 4
        }
    }

    /// Where the first bar begins: this week's first day, or the start of the week three weeks ago.
    func start(now: Date, calendar: Calendar) -> Date? {
        guard let thisWeek = calendar.startOfWeek(containing: now) else { return nil }
        return self == .thisWeek ? thisWeek : calendar.date(byAdding: .weekOfYear, value: -3, to: thisWeek)
    }
}

/// What Insights shows for a period: how many loops, when, what sets them off, and what the habit reached for most
/// gives. Like Home and Nice catch, the period counts up to now.
struct InsightsReport {
    /// One bar of the loops chart: a day, or a week.
    struct Bar: Equatable {
        let start: Date
        let count: Int
        /// Today, or this week, which the chart picks out.
        let isCurrent: Bool
    }

    /// A trigger, or a behavior, with how often it was logged in the period.
    struct Tally: Equatable {
        /// What history counts it by: the choice the logger shows, whichever copy of its words was logged.
        let id: String
        /// As last worded, so a renamed option shows its current text.
        let label: String
        let count: Int
    }

    /// What the habit logged most gave the person, out of every time it ran, as the trigger page counts. Unlike that
    /// page, the card waits for three clear results before it speaks.
    struct Habit: Equatable {
        /// As last worded.
        let label: String
        /// Every loop of it in the period.
        let total: Int
        /// How many of its loops have a result that says how it went: a core result other than "Not sure".
        let clearResults: Int
        /// The ones that brought more worry, tension or no change. "Not sure" and the person's own results count
        /// toward `total`, never here.
        let unrewarding: Int

        /// Three clear results before the card speaks, so it doesn't draw a lesson from one or two.
        var hasEnough: Bool {
            clearResults >= 3
        }
    }

    /// How many of some loops went a given way, for "no better 5 of 6 times".
    struct Share: Equatable {
        let count: Int
        let total: Int
    }

    let period: InsightsPeriod
    /// Oldest first.
    let bars: [Bar]
    /// The loops logged in the period up to now, oldest first.
    private let loops: [Loop]
    /// Each id a trigger or behavior was logged under, mapped to the choice the logger shows for it.
    private let choiceIDs: [String: String]
    private let calendar: Calendar
    private let now: Date

    var total: Int {
        bars.reduce(0) { $0 + $1.count }
    }

    var isEmpty: Bool {
        loops.isEmpty
    }

    /// `saved` is the person's options, so copies of one text count as the one choice the logger shows.
    init(loops: [Loop], saved: [LoopOption], period: InsightsPeriod, now: Date, calendar: Calendar) {
        self.period = period
        self.calendar = calendar
        self.now = now
        let first = period.start(now: now, calendar: calendar) ?? now
        let inPeriod = loops.filter { $0.createdAt >= first && $0.createdAt <= now }
        self.loops = inPeriod.sorted { $0.createdAt < $1.createdAt }
        bars = (0 ..< period.barCount).compactMap { offset in
            guard
                let start = calendar.date(byAdding: period.unit, value: offset, to: first),
                let end = calendar.date(byAdding: period.unit, value: 1, to: start)
            else { return nil }
            return Bar(
                start: start,
                count: inPeriod.count { (start ..< end).contains($0.createdAt) },
                isCurrent: (start ..< end).contains(now),
            )
        }
        var choiceIDs: [String: String] = [:]
        for choice in OptionList.choices(for: .trigger, saved: saved) + OptionList.choices(
            for: .behavior,
            saved: saved,
        ) {
            for id in [choice.id] + choice.mergedIDs {
                choiceIDs[id] = choice.id
            }
        }
        self.choiceIDs = choiceIDs
    }

    /// "Most loops start between 8 and 10 am": the hour that begins the two-hour stretch of the day with the most
    /// loops (0, 2, … 22), a tie going to the earlier. Only once there are five loops, so it means something.
    var busiestHours: Int? {
        guard loops.count >= 5 else { return nil }
        var counts: [Int: Int] = [:]
        for loop in loops {
            counts[calendar.component(.hour, from: loop.createdAt) / 2 * 2, default: 0] += 1
        }
        return counts.max { ($0.value, -$0.key) < ($1.value, -$1.key) }?.key
    }

    /// The busiest two hours as times on the person's clock, today, for the line to show.
    var busiestWindow: DateInterval? {
        guard
            let hour = busiestHours,
            let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now)
        else { return nil }
        return DateInterval(start: start, duration: 2 * 60 * 60)
    }

    /// Every trigger in the period, most logged first, a tie going to the one logged last, with what followed it.
    var triggers: [TriggerSummary] {
        ranked(loops, by: \.triggerID, label: \.triggerLabel).map { trigger in
            let followed = loops(setOffBy: trigger.id)
            let habits = followed.filter { $0.metWithTool == nil }
            return TriggerSummary(
                id: trigger.id,
                label: trigger.label,
                habits: habits.count,
                metWithTool: followed.count - habits.count,
                topHabit: ranked(habits, by: \.behaviorID, label: \.behaviorLabel).first,
            )
        }
    }

    /// The detail for the trigger with id `id`, as `triggers` gives it or any copy of it; `nil` if nothing in the
    /// period was set off by it.
    func trigger(_ id: String) -> TriggerDetail? {
        let followed = loops(setOffBy: choiceID(id))
        guard let label = followed.last?.triggerLabel else { return nil }
        let habits = followed.filter { $0.metWithTool == nil }
        let habitOutcomes = habits.map { ResultOutcome(resultID: $0.resultID) }
        let toolOutcomes = followed.filter { $0.metWithTool != nil }.map { ToolOutcome(resultID: $0.resultID) }
        return TriggerDetail(
            label: label,
            habits: habits.count,
            metWithTool: followed.count - habits.count,
            followedBy: ranked(followed, by: \.behaviorID, label: \.behaviorLabel).map { behavior in
                TriggerDetail.Followed(
                    label: behavior.label,
                    count: behavior.count,
                    isTool: QuickTool(behaviorID: behavior.id) != nil,
                )
            },
            habitsNoBetter: habitOutcomes.allSatisfy { $0 == .unclear } ? nil : Share(
                count: habitOutcomes.count { $0 == .noBetter },
                total: habitOutcomes.count,
            ),
            toolsLighter: toolOutcomes.allSatisfy { $0 == nil } ? nil : Share(
                count: toolOutcomes.count { $0 == .lighter },
                total: toolOutcomes.count,
            ),
            noticed: Array(habits.compactMap(\.noticed).suffix(8)),
            notes: Array(followed.reversed().compactMap { loop in
                loop.note.map {
                    TriggerDetail.Note(
                        text: $0,
                        behavior: loop.behaviorLabel,
                        result: loop.resultLabel,
                        date: loop.createdAt,
                    )
                }
            }
            .prefix(3)),
        )
    }

    /// The loops in the period set off by the trigger with id `id`, oldest first, whichever copy of it they logged.
    private func loops(setOffBy id: String) -> [Loop] {
        loops.filter { choiceID($0.triggerID) == id }
    }

    /// The behavior logged most in the period, and what it gave, for the card that helps the person see it plainly.
    /// Loops met with a tool are left out: a tool isn't a habit to see through.
    var habit: Habit? {
        let habits = loops.filter { $0.metWithTool == nil }
        guard let top = ranked(habits, by: \.behaviorID, label: \.behaviorLabel).first else { return nil }
        let outcomes = habits.filter { choiceID($0.behaviorID) == top.id }.map { ResultOutcome(resultID: $0.resultID) }
        return Habit(
            label: top.label,
            total: outcomes.count,
            clearResults: outcomes.count { $0 != .unclear },
            unrewarding: outcomes.count { $0 == .noBetter },
        )
    }

    private func choiceID(_ id: String) -> String {
        choiceIDs[id] ?? id
    }

    /// Every trigger or behavior in the period, most logged first, a tie going to the one logged last, each with the
    /// words it was last logged with.
    private func ranked(_ loops: [Loop], by id: KeyPath<Loop, String>, label: KeyPath<Loop, String>) -> [Tally] {
        var tallies: [String: (count: Int, last: Loop)] = [:]
        for loop in loops {
            let choice = choiceID(loop[keyPath: id])
            tallies[choice, default: (0, loop)].count += 1
            tallies[choice]?.last = loop
        }
        return tallies
            .sorted { ($0.value.count, $0.value.last.createdAt) > ($1.value.count, $1.value.last.createdAt) }
            .map { Tally(id: $0.key, label: $0.value.last[keyPath: label], count: $0.value.count) }
    }
}

/// A trigger, with what the person did after it in the period: the habit, or a tool to meet the urge. A row of
/// Insights' "What sets you off".
struct TriggerSummary: Equatable {
    /// What history counts it by, as in `InsightsReport.Tally`.
    let id: String
    /// As last worded.
    let label: String
    /// Loops where a habit followed it.
    let habits: Int
    /// Loops where the person met the urge with a tool instead.
    let metWithTool: Int
    /// The habit it led to most, as last worded; `nil` if only tools followed it.
    let topHabit: InsightsReport.Tally?

    /// What the row's line says.
    enum Line: Equatable {
        /// "Met it with a tool 2 of 6 times."
        case metWithTool(Int, of: Int)
        /// "Kept checking 4 times."
        case habit(label: String, count: Int)
    }

    /// Once the trigger has been met with a tool, how often, since meeting the urge is the progress that matters;
    /// until then, the habit it led to most.
    var line: Line {
        if metWithTool == 0, let topHabit {
            .habit(label: topHabit.label, count: topHabit.count)
        } else {
            .metWithTool(metWithTool, of: habits + metWithTool)
        }
    }
}

/// One trigger in detail, for its page: what followed it in the period and what that gave the person.
struct TriggerDetail: Equatable {
    /// A habit or a tool that followed the trigger, and how often.
    struct Followed: Equatable {
        /// As last worded.
        let label: String
        let count: Int
        /// Whether the person met the urge with this tool, rather than a habit running.
        let isTool: Bool
    }

    /// A note the person wrote after the trigger, in their own words, with the loop it was about.
    struct Note: Equatable {
        let text: String
        let behavior: String
        let result: String
        let date: Date
    }

    /// As last worded.
    let label: String
    /// Loops where a habit followed it.
    let habits: Int
    /// Loops where the person met the urge with a tool instead.
    let metWithTool: Int
    /// Most logged first, a tie going to the one logged last.
    let followedBy: [Followed]
    /// Of all its habits, the ones that brought more worry, tension or no change, so the total matches what followed
    /// it; `nil` until one has a clear result, as there's nothing to say before then.
    let habitsNoBetter: InsightsReport.Share?
    /// Of all its tool runs, the ones that left the person lighter; `nil` until one has a Lighter, About the same or
    /// Heavier answer.
    let toolsLighter: InsightsReport.Share?
    /// When the person noticed its last eight habits that say, oldest first. Tool runs have no answer: the person met
    /// the urge before a habit ran.
    let noticed: [NoticeTiming]
    /// Its latest three notes, newest first.
    let notes: [Note]

    /// Its loops in the period.
    var total: Int {
        habits + metWithTool
    }
}
