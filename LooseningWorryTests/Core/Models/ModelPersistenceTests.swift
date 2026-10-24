import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

struct ModelPersistenceTests {
    let container: ModelContainer

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
    }

    /// Saves in one context and returns a fresh context, so reads come from the store, not memory.
    private func save<each Model: PersistentModel>(_ models: repeat each Model) throws -> ModelContext {
        let writer = ModelContext(container)
        repeat writer.insert(each models)
        try writer.save()
        return ModelContext(container)
    }

    @Test
    func `a saved loop reads back with its details`() throws {
        let createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        let loop = Loop(trigger: "Email from boss", behavior: "Reread it", result: "Felt worse")
        loop.createdAt = createdAt
        loop.anxiety = 7
        loop.note = "Before the 1:1"

        let reader = try save(loop)
        let fetched = try #require(try reader.fetch(FetchDescriptor<Loop>()).only)

        #expect(fetched.trigger == "Email from boss")
        #expect(fetched.behavior == "Reread it")
        #expect(fetched.result == "Felt worse")
        #expect(fetched.createdAt == createdAt)
        #expect(fetched.anxiety == 7)
        #expect(fetched.note == "Before the 1:1")
    }

    @Test
    func `deleting a loop keeps the tool sessions started from it`() throws {
        let loop = Loop(trigger: "Email from boss", behavior: "Reread it", result: "Felt worse")
        let session = ToolSession(tool: .breathe)
        session.loop = loop

        let context = try save(loop, session)
        let fetchedLoop = try #require(try context.fetch(FetchDescriptor<Loop>()).only)
        context.delete(fetchedLoop)
        try context.save()

        let sessions = try ModelContext(container).fetch(FetchDescriptor<ToolSession>())
        let fetchedSession = try #require(sessions.only)
        #expect(fetchedSession.tool == .breathe)
        #expect(fetchedSession.loop == nil)
    }

    @Test
    func `lesson progress reads back with when it was completed and last revisited`() throws {
        let completedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let lastRevisitedAt = Date(timeIntervalSince1970: 1_803_000_000)
        let progress = LessonProgress(day: 8)
        progress.completedAt = completedAt
        progress.lastRevisitedAt = lastRevisitedAt

        let reader = try save(progress)
        let fetched = try #require(try reader.fetch(FetchDescriptor<LessonProgress>()).only)

        #expect(fetched.day == 8)
        #expect(fetched.completedAt == completedAt)
        #expect(fetched.lastRevisitedAt == lastRevisitedAt)
    }

    @Test(arguments: [OptionKind.trigger, .behavior, .result])
    func `an option reads back with its kind`(kind: OptionKind) throws {
        let reader = try save(LoopOption(kind: kind, label: "Checked my phone"))
        let fetched = try #require(try reader.fetch(FetchDescriptor<LoopOption>()).only)

        #expect(fetched.kind == kind)
        #expect(fetched.label == "Checked my phone")
        #expect(fetched.starterID == nil)
    }

    @Test
    func `a starter override reads back with the starter it changes`() throws {
        let updatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let override = LoopOption(kind: .trigger, label: "World news", starterID: "trigger.news")
        override.isHidden = true
        override.updatedAt = updatedAt

        let reader = try save(override)
        let fetched = try #require(try reader.fetch(FetchDescriptor<LoopOption>()).only)

        #expect(fetched.starterID == "trigger.news")
        #expect(fetched.label == "World news")
        #expect(fetched.isHidden)
        #expect(fetched.updatedAt == updatedAt)
    }

    @Test(arguments: [QuickTool.curious, .breathe, .noteIt, .beKind], [Feeling.lighter, .same, .heavier])
    func `a tool session reads back with its tool and feeling`(tool: QuickTool, feeling: Feeling) throws {
        let session = ToolSession(tool: tool)
        session.feeling = feeling

        let reader = try save(session)
        let fetched = try #require(try reader.fetch(FetchDescriptor<ToolSession>()).only)

        #expect(fetched.tool == tool)
        #expect(fetched.feeling == feeling)
    }
}

private extension Array {
    /// The sole element, or nil when there are none or several.
    var only: Element? {
        count == 1 ? first : nil
    }
}
