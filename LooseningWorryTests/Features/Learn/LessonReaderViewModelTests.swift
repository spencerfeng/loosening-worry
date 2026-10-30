import Foundation
@testable import LooseningWorry
import Testing

@MainActor
struct LessonReaderViewModelTests {
    private final class Progress: LessonCompleting {
        var completed: [(day: Int, date: Date)] = []
        var fails = false

        func complete(day: Int, at date: Date) throws {
            if fails {
                throw CocoaError(.fileWriteUnknown)
            }
            completed.append((day, date))
        }
    }

    private let now = Date(timeIntervalSince1970: 1_793_000_000)
    private let progress = Progress()

    private func reader(day: Int = 2) throws -> LessonReaderViewModel {
        try LessonReaderViewModel(lesson: #require(LessonCatalog.bundled.lesson(day: day)), progress: progress)
    }

    @Test
    func `a lesson opens on its first card`() throws {
        let reader = try reader()

        #expect(reader.index == 0)
        #expect(reader.card.kind == .hook)
        #expect(reader.isFirst)
        #expect(!reader.isFinished)
    }

    @Test
    func `next and back move through the cards, never before the first`() throws {
        let reader = try reader()

        reader.next(now: now)
        reader.next(now: now)
        reader.back()
        #expect(reader.index == 1)

        reader.back()
        reader.back()
        #expect(reader.index == 0)
    }

    @Test
    func `next on the last card finishes the lesson and saves it`() throws {
        let reader = try reader()
        for _ in reader.lesson.cards.indices.dropLast() {
            reader.next(now: now)
        }
        #expect(reader.isLast)
        #expect(progress.completed.isEmpty)

        reader.next(now: now)

        #expect(reader.isFinished)
        #expect(progress.completed.map(\.day) == [2])
        #expect(progress.completed.map(\.date) == [now])
    }

    /// The task button marks the lesson done and says where to go, so the reader can close and open it.
    @Test
    func `starting today's task finishes the lesson and gives its action`() throws {
        let reader = try reader(day: 21)

        let action = reader.startTask(now: now)

        #expect(action == .tool(.curious))
        #expect(progress.completed.map(\.day) == [21])
    }

    /// The reader closes straight to the task, so the done screen mustn't show as it goes.
    @Test
    func `starting today's task doesn't show the done screen`() throws {
        let reader = try reader(day: 21)

        _ = reader.startTask(now: now)

        #expect(!reader.isFinished)
    }

    /// The lesson was still read; only the tick is missing, and the person is told.
    @Test
    func `a lesson that can't be saved still finishes, and says so`() throws {
        progress.fails = true
        let reader = try reader()
        for _ in reader.lesson.cards.indices {
            reader.next(now: now)
        }

        #expect(reader.isFinished)
        #expect(reader.didFailToSave)
    }
}
