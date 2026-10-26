import Foundation
import os

/// One day of the 30-day course.
struct Lesson: Decodable, Equatable, Sendable {
    let day: Int
    let title: String
    /// How long it takes to read.
    let minutes: Int
}

/// The course's lessons, from `lessons.json`. Days 1–5 are written; the rest carry the outline's planned titles, and
/// the Learn milestone adds each lesson's text.
struct LessonCatalog: Sendable {
    /// In day order.
    let lessons: [Lesson]

    init(json: Data) throws {
        lessons = try JSONDecoder().decode([Lesson].self, from: json).sorted { $0.day < $1.day }
    }

    func lesson(day: Int) -> Lesson? {
        lessons.first { $0.day == day }
    }

    /// The lessons shipped with the app. Tests check there are thirty, one a day.
    static let bundled: LessonCatalog = {
        guard let url = Bundle.main.url(forResource: "lessons", withExtension: "json") else {
            return loaded(from: nil)
        }
        do {
            return try loaded(from: Data(contentsOf: url))
        } catch {
            logger.error("Couldn't read lessons.json: \(error)")
            return LessonCatalog(lessons: [])
        }
    }()

    /// The lessons in `data`, or none if there's no file or it can't be read: Home then leaves the lesson card out.
    static func loaded(from data: Data?) -> LessonCatalog {
        guard let data else {
            logger.error("lessons.json is missing from the app")
            return LessonCatalog(lessons: [])
        }
        do {
            return try LessonCatalog(json: data)
        } catch {
            logger.error("Couldn't decode lessons.json: \(error)")
            return LessonCatalog(lessons: [])
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Lessons")

    private init(lessons: [Lesson]) {
        self.lessons = lessons
    }
}
