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
        let ownTrigger = LoopOption(kind: .trigger, label: "Email from boss")
        let loop = Loop(
            trigger: OptionChoice(ownTrigger),
            behavior: OptionChoice(.keptChecking, label: "Reread it"),
            result: OptionChoice(.moreWorry, label: "More worry"),
        )
        loop.createdAt = createdAt
        loop.anxiety = 7
        loop.note = "Before the 1:1"

        let reader = try save(loop)
        let fetched = try #require(try reader.fetch(FetchDescriptor<Loop>()).only)

        #expect(fetched.triggerID == ownTrigger.optionID)
        #expect(fetched.triggerLabel == "Email from boss")
        #expect(fetched.behaviorID == "behavior.keptChecking")
        #expect(fetched.behaviorLabel == "Reread it")
        #expect(fetched.resultID == "result.moreWorry")
        #expect(fetched.resultLabel == "More worry")
        #expect(fetched.createdAt == createdAt)
        #expect(fetched.anxiety == 7)
        #expect(fetched.note == "Before the 1:1")
    }

    @Test
    func `deleting a loop keeps the tool sessions started from it`() throws {
        let loop = Loop(
            trigger: OptionChoice(.work, label: "Work"),
            behavior: OptionChoice(.keptChecking, label: "Kept checking"),
            result: OptionChoice(.moreWorry, label: "More worry"),
        )
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
        let option = LoopOption(kind: kind, label: "Checked my phone")
        let reader = try save(option)
        let fetched = try #require(try reader.fetch(FetchDescriptor<LoopOption>()).only)

        #expect(fetched.optionID == option.optionID)
        #expect(fetched.kind == kind)
        #expect(fetched.label == "Checked my phone")
        #expect(fetched.starterID == nil)
    }

    /// Loops count an option by this id, so two options must never share one, even when added at the same moment.
    @Test
    func `every new option gets its own id`() {
        let options = (1 ... 3).map { _ in LoopOption(kind: .trigger, label: "Rent due") }

        #expect(Set(options.map(\.optionID)).count == 3)
        #expect(options.allSatisfy { $0.optionID.hasPrefix("custom.") })
    }

    @Test
    func `a starter override reads back with the starter it changes`() throws {
        let updatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let override = LoopOption(overriding: .news, label: "News")
        override.isHidden = true
        override.updatedAt = updatedAt

        let reader = try save(override)
        let fetched = try #require(try reader.fetch(FetchDescriptor<LoopOption>()).only)

        #expect(fetched.starter == .news)
        #expect(fetched.label == "News")
        #expect(fetched.isHidden)
        #expect(fetched.updatedAt == updatedAt)
    }

    @Test
    func `an override knows the starter it changes`() {
        let override = LoopOption(overriding: .news, label: "News")

        #expect(override.kind == .trigger)
        #expect(override.starter == .news)
        #expect(override.starterID == "trigger.news")
    }

    /// A newer version on another device can sync an override of a starter this version doesn't have.
    @Test
    func `an override of a starter this version doesn't know has no starter`() {
        let override = LoopOption(overriding: .news, label: "News")

        override.starterID = "trigger.addedLater"

        #expect(override.starter == nil)
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
