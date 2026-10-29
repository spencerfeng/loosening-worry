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

    /// What the habit logged most gave the person, among its loops with a clear result.
    struct Habit: Equatable {
        /// As last worded.
        let label: String
        /// How many of its loops have a result that says how it went: a core result other than "Not sure".
        let clearResults: Int
        /// Of those, the ones that brought more worry, tension or no change.
        let unrewarding: Int

        /// Three clear results before the card speaks, so it doesn't draw a lesson from one or two.
        var hasEnough: Bool {
            clearResults >= 3
        }
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

    /// The three triggers logged most, a tie going to the one logged last.
    var topTriggers: [Tally] {
        Array(ranked(by: \.triggerID, label: \.triggerLabel).prefix(3))
    }

    /// The behavior logged most in the period, and what it gave, for the card that helps the person see it plainly.
    var habit: Habit? {
        guard let top = ranked(by: \.behaviorID, label: \.behaviorLabel).first else { return nil }
        let results = loops.filter { choiceID($0.behaviorID) == top.id }.compactMap { StarterID(rawValue: $0.resultID) }
        let clear = results.filter(\.isClearResult)
        return Habit(
            label: top.label,
            clearResults: clear.count,
            unrewarding: clear.count(where: \.isUnrewardingResult),
        )
    }

    private func choiceID(_ id: String) -> String {
        choiceIDs[id] ?? id
    }

    /// Every trigger or behavior in the period, most logged first, a tie going to the one logged last, each with the
    /// words it was last logged with.
    private func ranked(by id: KeyPath<Loop, String>, label: KeyPath<Loop, String>) -> [Tally] {
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
