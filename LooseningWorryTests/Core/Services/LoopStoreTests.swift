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
