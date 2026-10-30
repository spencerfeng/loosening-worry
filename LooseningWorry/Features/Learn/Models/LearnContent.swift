import Foundation

/// What the Learn tab lists: the course in its three stages, and where the person is in it.
enum LearnContent {
    enum Status: Equatable {
        case done
        /// The first lesson not yet done; lessons can be read in any order.
        case next
        case later
    }

    struct Row: Equatable {
        let lesson: Lesson
        let status: Status
    }

    /// Ten days of the course, numbered 1–3.
    struct Stage: Equatable {
        let number: Int
        let rows: [Row]
    }

    static let daysPerStage = 10

    static func stages(progress: [LessonProgress], catalog: LessonCatalog) -> [Stage] {
        let done = Set(progress.filter { $0.completedAt != nil }.map(\.day))
        let next = catalog.lessons.first { !done.contains($0.day) }?.day
        let rows = catalog.lessons.map { lesson in
            Row(
                lesson: lesson,
                status: done.contains(lesson.day) ? .done : lesson.day == next ? .next : .later,
            )
        }
        return Dictionary(grouping: rows) { ($0.lesson.day - 1) / daysPerStage + 1 }
            .sorted { $0.key < $1.key }
            .map { Stage(number: $0.key, rows: $0.value) }
    }
}
