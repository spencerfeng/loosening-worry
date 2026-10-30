import Foundation
import Observation
import os

/// Saves that a lesson is done; `LessonProgressStore` in the app, a stand-in in tests.
protocol LessonCompleting {
    func complete(day: Int, at date: Date) throws
}

extension LessonProgressStore: LessonCompleting {}

/// Steps through one lesson's cards. The lesson is done when the last card's Next is tapped, or when today's task
/// button takes the person to the task.
@Observable @MainActor
final class LessonReaderViewModel {
    let lesson: Lesson
    private(set) var index = 0
    private(set) var isFinished = false
    /// The lesson couldn't be saved as done; the finish screen says so.
    private(set) var didFailToSave = false

    private let progress: LessonCompleting

    init(lesson: Lesson, progress: LessonCompleting) {
        self.lesson = lesson
        self.progress = progress
    }

    var card: LessonCard {
        lesson.cards[index]
    }

    var isFirst: Bool {
        index == 0
    }

    var isLast: Bool {
        index == lesson.cards.count - 1
    }

    /// The next card, or on the last one, finishing the lesson.
    func next(now: Date) {
        if isLast {
            save(now: now)
            isFinished = true
        } else {
            index += 1
        }
    }

    func back() {
        index = max(index - 1, 0)
    }

    /// Saves the lesson as done and returns where its task button goes. The reader closes straight to the task, so the
    /// done screen isn't shown.
    func startTask(now: Date) -> LessonAction? {
        save(now: now)
        return lesson.cards.last?.action
    }

    private func save(now: Date) {
        do {
            try progress.complete(day: lesson.day, at: now)
        } catch {
            let day = lesson.day
            Self.logger.error("Couldn't save lesson \(day) as done: \(error)")
            didFailToSave = true
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Lessons")
}
