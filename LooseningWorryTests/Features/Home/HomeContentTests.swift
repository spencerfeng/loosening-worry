import Foundation
@testable import LooseningWorry
import Testing

struct HomeContentTests {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    /// A time in October 2026, UTC. The 21st is a Wednesday.
    private static func date(day: Int, hour: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)))
    }

    // MARK: - Greeting

    @Test(arguments: [
        (5, HomeContent.Greeting.morning), (11, .morning),
        (12, .afternoon), (17, .afternoon),
        (18, .evening), (23, .evening), (2, .evening), (4, .evening),
    ])
    func `the greeting follows the time of day`(hour: Int, greeting: HomeContent.Greeting) throws {
        let now = try Self.date(day: 21, hour: hour)

        #expect(HomeContent.greeting(at: now, calendar: Self.calendar) == greeting)
    }

    // MARK: - Lesson

    /// A course of its own, so these tests don't change when lessons.json does.
    private let catalog: LessonCatalog

    init() throws {
        catalog = try LessonCatalog(json: Data("""
        [{"day": 1, "title": "Welcome", "minutes": 5, "cards": []},
         {"day": 2, "title": "Your brain loves loops", "minutes": 5, "cards": []},
         {"day": 3, "title": "Worry as a behavior", "minutes": 6, "cards": []}]
        """.utf8))
    }

    private func completed(_ days: [Int]) -> [LessonProgress] {
        days.map { day in
            let progress = LessonProgress(day: day)
            progress.completedAt = .now
            return progress
        }
    }

    @Test
    func `a new person's next lesson is day 1`() throws {
        let card = try #require(HomeContent.nextLesson(progress: [], catalog: catalog))

        #expect(card.lesson.day == 1)
        #expect(card.lesson.title == "Welcome")
        #expect(card.daysCompleted == 0)
        #expect(card.totalDays == 3)
    }

    /// Lessons can be read out of order, so the next one is the first not yet done.
    @Test
    func `the next lesson is the first one not completed`() throws {
        let opened = LessonProgress(day: 2)

        let card = try #require(HomeContent.nextLesson(progress: completed([1, 3]) + [opened], catalog: catalog))

        #expect(card.lesson.day == 2)
        #expect(card.daysCompleted == 2)
    }

    @Test
    func `once every lesson is done there's no lesson card`() {
        #expect(HomeContent.nextLesson(progress: completed([1, 2, 3]), catalog: catalog) == nil)
    }

    // MARK: - This week

    /// The same calendar week as Nice catch's count, so the two agree.
    @Test
    func `this week counts the loops and tool sessions since the week began`() throws {
        let now = try Self.date(day: 21, hour: 12)
        let loops = try [18, 19, 20, 21].map { try Loop.sample(createdAt: Self.date(day: $0, hour: 9)) }
        let sessions = try [17, 20].map { day in
            let session = ToolSession(tool: .breathe)
            session.startedAt = try Self.date(day: day, hour: 9)
            return session
        }

        let week = HomeContent.thisWeek(loops: loops, sessions: sessions, now: now, calendar: Self.calendar)

        // The week began on Monday the 19th.
        #expect(week == HomeContent.WeekSummary(loops: 3, tools: 1))
    }

    @Test
    func `the week's first moment counts, and anything after now doesn't`() throws {
        let now = try Self.date(day: 21, hour: 12)
        let weekStart = try Self.date(day: 19, hour: 0)
        let later = ToolSession(tool: .breathe)
        later.startedAt = try Self.date(day: 21, hour: 13)

        let week = HomeContent.thisWeek(
            loops: [.sample(createdAt: weekStart), .sample(createdAt: weekStart.addingTimeInterval(-1))],
            sessions: [later],
            now: now,
            calendar: Self.calendar,
        )

        #expect(week == HomeContent.WeekSummary(loops: 1, tools: 0))
    }
}
