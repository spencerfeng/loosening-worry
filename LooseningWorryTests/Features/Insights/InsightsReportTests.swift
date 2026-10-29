import Foundation
@testable import LooseningWorry
import Testing

struct InsightsReportTests {
    /// Weeks start on Monday here, as in Australia; the report follows the person's own calendar.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney") ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Wednesday 28 October 2026, 3 pm.
    private var now: Date {
        date(day: 28, hour: 15)
    }

    private func date(day: Int, hour: Int, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)) ?? .distantPast
    }

    private func loop(
        _ createdAt: Date,
        trigger: (String, String) = ("trigger.work", "Work"),
        behavior: (String, String) = ("behavior.overthought", "Overthought it"),
        result: (String, String) = ("result.moreWorry", "More worry"),
    ) -> Loop {
        let loop = Loop(
            trigger: OptionChoice(id: trigger.0, label: trigger.1),
            behavior: OptionChoice(id: behavior.0, label: behavior.1),
            result: OptionChoice(id: result.0, label: result.1),
        )
        loop.createdAt = createdAt
        return loop
    }

    private func report(
        _ loops: [Loop],
        period: InsightsPeriod = .thisWeek,
        saved: [LoopOption] = [],
        calendar: Calendar? = nil,
    ) -> InsightsReport {
        InsightsReport(loops: loops, saved: saved, period: period, now: now, calendar: calendar ?? self.calendar)
    }

    @Test
    func `this week counts loops per day, in the person's own week, with the total`() {
        let loops = [
            loop(date(day: 26, hour: 9)), loop(date(day: 26, hour: 20)),
            loop(date(day: 28, hour: 8)),
            loop(date(day: 25, hour: 23)), // last Sunday: last week
        ]

        let report = report(loops)

        #expect(report.total == 3)
        #expect(report.bars.map(\.count) == [2, 0, 1, 0, 0, 0, 0])
        #expect(report.bars.first?.start == date(day: 26, hour: 0))
        #expect(report.bars.map(\.isCurrent) == [false, false, true, false, false, false, false])
    }

    /// Four weeks show whether loops are getting rarer: the current week last.
    @Test
    func `the last four weeks count loops per week, oldest first`() {
        let loops = [
            loop(date(day: 5, hour: 9)), // week of 5 Oct
            loop(date(day: 13, hour: 9)), loop(date(day: 18, hour: 9)), // week of 12 Oct
            loop(date(day: 27, hour: 9)), // this week
            loop(date(day: 4, hour: 9)), // week of 28 Sep: too long ago
        ]

        let report = report(loops, period: .lastFourWeeks)

        #expect(report.bars.map(\.count) == [1, 2, 0, 1])
        #expect(report.bars.first?.start == date(day: 5, hour: 0))
        #expect(report.bars.map(\.isCurrent) == [false, false, false, true])
        #expect(report.total == 4)
    }

    /// The triggers logged most in the period, a tie going to the one logged last; each shown as it was last worded.
    @Test
    func `top triggers are the three logged most, ties to the most recent, in their latest words`() {
        let work = ("trigger.work", "Work")
        let money = ("trigger.money", "Money")
        let news = ("trigger.news", "News")
        let sleep = ("trigger.tryingToSleep", "Trying to sleep")
        let loops = [
            loop(date(day: 26, hour: 8), trigger: work),
            loop(date(day: 26, hour: 9), trigger: ("trigger.work", "Work stuff")),
            loop(date(day: 26, hour: 10), trigger: money),
            loop(date(day: 27, hour: 10), trigger: money),
            loop(date(day: 27, hour: 11), trigger: news),
            loop(date(day: 28, hour: 9), trigger: sleep),
            loop(date(day: 20, hour: 9), trigger: news), // last week
        ]

        let triggers = report(loops).topTriggers

        #expect(triggers.map(\.label) == ["Money", "Work stuff", "Trying to sleep"])
        #expect(triggers.map(\.count) == [2, 2, 1])
    }

    /// "Most loops start between 8 and 10 am": the two-hour stretch of the day with the most loops.
    @Test
    func `the busiest two hours are named once there are five loops`() {
        let four = [
            loop(date(day: 26, hour: 8)), loop(date(day: 26, hour: 9)), loop(date(day: 27, hour: 9)),
            loop(date(day: 27, hour: 20)),
        ]
        #expect(report(four).busiestHours == nil)

        let five = four + [loop(date(day: 28, hour: 13))]

        #expect(report(five).busiestHours == 8)
    }

    @Test
    func `a tie for the busiest two hours goes to the earlier`() {
        let loops = [
            loop(date(day: 26, hour: 20)), loop(date(day: 26, hour: 21)),
            loop(date(day: 27, hour: 6)), loop(date(day: 27, hour: 7)),
            loop(date(day: 28, hour: 13)),
        ]

        #expect(report(loops).busiestHours == 6)
    }

    /// What the habit logged most gave the person: of its loops with a clear result, how many brought more worry,
    /// tension or no change. "Not sure" and the person's own results say nothing either way, so they're left out.
    @Test
    func `the habit card counts what the top behavior gave, among clear results`() throws {
        let overthought = ("behavior.overthought", "Overthought it")
        let checked = ("behavior.keptChecking", "Kept checking")
        let loops = [
            loop(date(day: 26, hour: 8), behavior: overthought, result: ("result.moreWorry", "More worry")),
            loop(date(day: 26, hour: 9), behavior: overthought, result: ("result.tenseAndTired", "Tense and tired")),
            loop(date(day: 27, hour: 9), behavior: overthought, result: ("result.littleRelief", "A little relief")),
            loop(date(day: 27, hour: 10), behavior: overthought, result: ("result.notSure", "Not sure")),
            loop(date(day: 27, hour: 11), behavior: overthought, result: ("custom.1", "Hungry")),
            loop(date(day: 28, hour: 9), behavior: checked, result: ("result.nothingChanged", "Nothing changed")),
        ]

        let habit = try #require(report(loops).habit)

        #expect(habit.label == "Overthought it")
        #expect(habit.clearResults == 3)
        #expect(habit.unrewarding == 2)
        #expect(habit.hasEnough)
    }

    /// Until a habit has three loops with a clear result, the card says more loops will tell.
    @Test
    func `the habit card waits for three clear results`() throws {
        let loops = [
            loop(date(day: 26, hour: 8)),
            loop(date(day: 27, hour: 9), result: ("result.notSure", "Not sure")),
            loop(date(day: 28, hour: 9)),
        ]

        let habit = try #require(report(loops).habit)

        #expect(habit.clearResults == 2)
        #expect(habit.hasEnough == false)
    }

    @Test
    func `with no loops in the period there's nothing to show`() {
        let report = report([loop(date(day: 12, hour: 9))])

        #expect(report.total == 0)
        #expect(report.isEmpty)
        #expect(report.habit == nil)
        #expect(report.topTriggers.isEmpty)
    }

    /// As in the logger, the person's own option with a starter's words is the same choice, and counts as one.
    @Test
    func `a starter and the person's own option with its words count as one trigger`() {
        let own = LoopOption(kind: .trigger, label: "Work")
        let loops = [
            loop(date(day: 26, hour: 8), trigger: ("trigger.work", "Work")),
            loop(date(day: 27, hour: 8), trigger: (own.optionID, "Work")),
            loop(date(day: 27, hour: 9), trigger: ("trigger.money", "Money")),
        ]

        let triggers = report(loops, saved: [own]).topTriggers

        #expect(triggers.map(\.label) == ["Work", "Money"])
        #expect(triggers.map(\.count) == [2, 1])
    }

    /// Like Home and Nice catch, the week counts up to now; a loop dated later, from a device with its clock ahead,
    /// waits until its time comes.
    @Test
    func `loops dated later than now don't count yet`() {
        let loops = [loop(date(day: 28, hour: 9)), loop(date(day: 28, hour: 20))]

        let report = report(loops)

        #expect(report.total == 1)
    }

    /// Where weeks start on Sunday, the bars do too.
    @Test
    func `the week starts on the person's own first day`() {
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1
        let loops = [loop(date(day: 25, hour: 9))] // Sunday

        let report = report(loops, calendar: sundayFirst)

        #expect(report.bars.first?.start == date(day: 25, hour: 0))
        #expect(report.bars.first?.count == 1)
    }

    /// "Most loops start between 10 pm and midnight": the window as times on the person's clock.
    @Test
    func `the busiest window runs from its first hour to two hours on, past midnight too`() throws {
        let loops = [(26, 22), (26, 23), (27, 22), (27, 23), (26, 22)].map { loop(date(day: $0.0, hour: $0.1)) }

        let window = try #require(report(loops).busiestWindow)

        #expect(calendar.component(.hour, from: window.start) == 22)
        #expect(window.duration == 2 * 60 * 60)
    }
}
