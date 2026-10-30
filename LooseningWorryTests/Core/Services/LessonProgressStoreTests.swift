import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
struct LessonProgressStoreTests {
    private let container: ModelContainer
    private let monday = Date(timeIntervalSince1970: 1_793_000_000)

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
    }

    private var store: LessonProgressStore {
        LessonProgressStore(context: container.mainContext)
    }

    private func saved() throws -> [LessonProgress] {
        try container.mainContext.fetch(FetchDescriptor<LessonProgress>())
    }

    @Test
    func `finishing a lesson saves the day and when it was done`() throws {
        try store.complete(day: 3, at: monday)

        let progress = try #require(try saved().only)
        #expect(progress.day == 3)
        #expect(progress.completedAt == monday)
    }

    /// Reading a lesson again doesn't move its date or count it twice.
    @Test
    func `finishing a lesson again keeps the first time it was done`() throws {
        try store.complete(day: 3, at: monday)

        try store.complete(day: 3, at: monday.addingTimeInterval(86400))

        let progress = try #require(try saved().only)
        #expect(progress.completedAt == monday)
    }

    /// Home can leave a row for a lesson it suggested revisiting before it was ever finished.
    @Test
    func `a lesson with a row but no date is marked done on that row`() throws {
        container.mainContext.insert(LessonProgress(day: 4))

        try store.complete(day: 4, at: monday)

        let progress = try #require(try saved().only)
        #expect(progress.completedAt == monday)
    }

    @Test
    func `the next lesson is the first not yet done`() throws {
        try store.complete(day: 1, at: monday)
        try store.complete(day: 2, at: monday)
        try store.complete(day: 4, at: monday)

        #expect(try store.nextLesson(in: .bundled)?.day == 3)
    }

    @Test
    func `once every lesson is done there's no next lesson`() throws {
        for day in 1 ... 30 {
            try store.complete(day: day, at: monday)
        }

        #expect(try store.nextLesson(in: .bundled) == nil)
    }
}
