import Foundation

/// What Home shows, worked out from the person's data: a greeting, today's lesson and a line about the week. Home keeps
/// no state of its own, so this is a set of rules rather than a view model.
enum HomeContent {
    enum Greeting: Equatable {
        case morning, afternoon, evening
    }

    /// The lesson card: the next lesson not yet completed, and how far through the course the person is.
    struct LessonCard: Equatable {
        let lesson: Lesson
        let daysCompleted: Int
        let totalDays: Int
    }

    /// This calendar week so far.
    struct WeekSummary: Equatable {
        let loops: Int
        let tools: Int
    }

    /// Morning from 5 am, afternoon from noon, evening from 6 pm through the night.
    static func greeting(at date: Date, calendar: Calendar) -> Greeting {
        switch calendar.component(.hour, from: date) {
        case 5 ..< 12: .morning
        case 12 ..< 18: .afternoon
        default: .evening
        }
    }

    /// The first lesson not yet completed, since lessons can be read out of order; `nil` once all are done.
    static func nextLesson(progress: [LessonProgress], catalog: LessonCatalog) -> LessonCard? {
        let done = Set(progress.filter { $0.completedAt != nil }.map(\.day))
        guard let next = catalog.lessons.first(where: { !done.contains($0.day) }) else { return nil }
        let completed = catalog.lessons.count { done.contains($0.day) }
        return LessonCard(lesson: next, daysCompleted: completed, totalDays: catalog.lessons.count)
    }

    /// Loops logged and tools used since this calendar week began, up to now.
    static func thisWeek(loops: [Loop], sessions: [ToolSession], now: Date, calendar: Calendar) -> WeekSummary {
        guard let start = calendar.startOfWeek(containing: now) else { return WeekSummary(loops: 0, tools: 0) }
        let thisWeek = start ... now
        return WeekSummary(
            loops: loops.count { thisWeek.contains($0.createdAt) },
            tools: sessions.count { thisWeek.contains($0.startedAt) },
        )
    }
}
