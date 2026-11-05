import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
struct LoopStoreTests {
    let container: ModelContainer

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
    }

    /// The logger closes once Save succeeds, so the loop must be in the store by then.
    @Test
    func `an added loop is saved straight away`() throws {
        try LoopStore(context: ModelContext(container)).add(.sample(trigger: OptionChoice(.news, label: "News")))

        let loops = try ModelContext(container).fetch(FetchDescriptor<Loop>())
        #expect(loops.map(\.triggerID) == ["trigger.news"])
    }

    /// Nice catch counts the calendar week so far, the way Insights' weekly chart will. A loop dated later than now,
    /// say from a device whose clock runs fast, isn't counted yet.
    @Test(arguments: [
        // Monday-first weeks start on the 19th, so Sunday the 18th is last week.
        (2, 3),
        // Sunday-first weeks start on the 18th, so it counts.
        (1, 4),
    ])
    func `this week's count starts on the region's first day of the week`(firstWeekday: Int, count: Int) throws {
        var calendar = Self.gmtCalendar
        calendar.firstWeekday = firstWeekday
        let store = LoopStore(context: ModelContext(container))
        for (day, hour) in [(11, 9), (18, 10), (19, 0), (20, 22), (21, 11), (21, 15)] {
            try store.add(.sample(createdAt: Self.date(day: day, hour: hour)))
        }
        // Wednesday, midday.
        let now = try Self.date(day: 21, hour: 12)

        #expect(try store.loopsThisWeek(now: now, calendar: calendar) == count)
    }

    /// The logger reads only the history its ordering uses.
    @Test
    func `loops since a date leave out older ones`() throws {
        let store = LoopStore(context: ModelContext(container))
        for day in [1, 10, 20] {
            try store.add(.sample(createdAt: Self.date(day: day, hour: 12)))
        }

        let loops = try store.loops(since: Self.date(day: 10, hour: 12))

        #expect(try loops.map(\.createdAt).sorted() == [Self.date(day: 10, hour: 12), Self.date(day: 20, hour: 12)])
    }

    /// Nice catch compares with the last time this trigger set the person off and they said when they noticed.
    @Test
    func `the last answer for a trigger skips unanswered loops and other triggers`() throws {
        let store = LoopStore(context: ModelContext(container))
        let work = OptionChoice(.work, label: "Work")
        try store.add(.sample(trigger: work, createdAt: Self.date(day: 1, hour: 12), noticed: .afterwards))
        try store.add(.sample(trigger: work, createdAt: Self.date(day: 5, hour: 12), noticed: .partway))
        try store.add(.sample(trigger: work, createdAt: Self.date(day: 8, hour: 12)))
        try store.add(.sample(
            trigger: OptionChoice(.news, label: "News"),
            createdAt: Self.date(day: 9, hour: 12),
            noticed: .asItStarted,
        ))

        #expect(try store.lastNoticed(forTrigger: "trigger.work") == .partway)
        #expect(try store.lastNoticed(forTrigger: "trigger.money") == nil)
    }

    /// Meeting the urge with a tool is noticing it as it started by definition, so comparing with it would leave the
    /// next habit nothing to improve on: the comparison is with the habits.
    @Test
    func `the last answer for a trigger skips loops met with a tool`() throws {
        let store = LoopStore(context: ModelContext(container))
        let work = OptionChoice(.work, label: "Work")
        try store.add(.sample(trigger: work, createdAt: Self.date(day: 1, hour: 12), noticed: .afterwards))
        try store.add(.sample(
            trigger: work,
            behavior: QuickTool.curious.asBehavior,
            createdAt: Self.date(day: 5, hour: 12),
            noticed: .asItStarted,
        ))

        #expect(try store.lastNoticed(forTrigger: "trigger.work") == .afterwards)
    }

    /// "Nothing yet, I'm in it now" shows what the person wrote the last time this trigger set them off.
    @Test
    func `the last note for a trigger skips loops without one and other triggers`() throws {
        let store = LoopStore(context: ModelContext(container))
        let work = OptionChoice(.work, label: "Work")
        for (day, note) in [(1, "Inbox dread"), (5, "Awake till 2, chest tight"), (8, nil)] {
            let loop = try Loop.sample(trigger: work, createdAt: Self.date(day: day, hour: 12))
            loop.note = note
            try store.add(loop)
        }
        let news = try Loop.sample(trigger: OptionChoice(.news, label: "News"), createdAt: Self.date(day: 9, hour: 12))
        news.note = "Doomscrolled"
        try store.add(news)

        #expect(try store.lastNoted(forTrigger: "trigger.work")?.note == "Awake till 2, chest tight")
        #expect(try store.lastNoted(forTrigger: "trigger.money") == nil)
    }

    private static var gmtCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    /// A time in October 2026, UTC.
    private static func date(day: Int, hour: Int) throws -> Date {
        try #require(gmtCalendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)))
    }
}
