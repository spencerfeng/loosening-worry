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

    /// Nice catch's "The last 5 times": this trigger leading to this habit, and nothing else.
    @Test
    func `the loops like one are its trigger and habit, oldest first`() throws {
        let store = LoopStore(context: ModelContext(container))
        for day in [3, 1, 2] {
            try store.add(.sample(createdAt: Self.date(day: day, hour: 12)))
        }
        try store.add(.sample(trigger: OptionChoice(.news, label: "News"), createdAt: Self.date(day: 8, hour: 12)))
        try store.add(.sample(
            behavior: OptionChoice(.scrolled, label: "Scrolled"),
            createdAt: Self.date(day: 9, hour: 12),
        ))
        // Meeting the urge with a tool is never the habit.
        try store.add(.sample(behavior: QuickTool.curious.asBehavior, createdAt: Self.date(day: 10, hour: 12)))
        let latest = try Loop.sample(createdAt: Self.date(day: 11, hour: 12))
        try store.add(latest)

        let loops = try store.loops(like: latest)

        #expect(try loops.map(\.createdAt) == [1, 2, 3, 11].map { try Self.date(day: $0, hour: 12) })
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
