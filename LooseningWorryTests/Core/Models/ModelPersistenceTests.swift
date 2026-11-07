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

    @Test(arguments: OptionKind.allCases)
    func `an option reads back with its kind`(kind: OptionKind) throws {
        let option = LoopOption(kind: kind, label: "Checked my phone")
        let reader = try save(option)
        let fetched = try #require(try reader.fetch(FetchDescriptor<LoopOption>()).only)

        #expect(fetched.optionID == option.optionID)
        #expect(fetched.kind == kind)
        #expect(fetched.label == "Checked my phone")
        #expect(fetched.starterID == nil)
    }

    /// Decoding is what SwiftData does to a stored kind; `OptionKindStoreTests` reads one from a real store.
    @Test
    func `a kind from a newer version decodes as unrecognized`() throws {
        let kinds = try JSONDecoder().decode([OptionKind].self, from: Data(#"["result", "addedLater"]"#.utf8))

        #expect(kinds == [.result, .unrecognized])
        #expect(!OptionKind.allCases.contains(.unrecognized))
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

    @Test(arguments: [QuickTool.curious, .breathe, .noteIt, .beKind], [ToolOutcome.lighter, .same, .heavier])
    func `a tool session reads back with its tool and outcome`(tool: QuickTool, outcome: ToolOutcome) throws {
        let session = ToolSession(tool: tool)
        session.outcome = outcome

        let reader = try save(session)
        let fetched = try #require(try reader.fetch(FetchDescriptor<ToolSession>()).only)

        #expect(fetched.tool == tool)
        #expect(fetched.outcome == outcome)
    }

    @Test
    func `a check-in reads back with how it felt and the words picked, in order`() throws {
        let createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        let checkIn = CheckIn(CheckInAnswer(pleasantness: .unpleasant, feelings: [.overwhelmed, .anxious]))
        checkIn.createdAt = createdAt

        let reader = try save(checkIn)
        let fetched = try #require(try reader.fetch(FetchDescriptor<CheckIn>()).only)

        #expect(fetched.createdAt == createdAt)
        #expect(fetched.pleasantness == .unpleasant)
        #expect(fetched.feelings == [.overwhelmed, .anxious])
    }

    @Test
    func `a check-in reads back with its contexts' ids and text, in order`() throws {
        let checkIn = CheckIn(CheckInAnswer(pleasantness: .neutral, feelings: [], contexts: [
            OptionChoice(.contextWork, label: "Work"),
            OptionChoice(id: "own-1", label: "Moving house"),
        ]))

        let reader = try save(checkIn)
        let fetched = try #require(try reader.fetch(FetchDescriptor<CheckIn>()).only)

        #expect(fetched.contextIDs == ["context.work", "own-1"])
        #expect(fetched.contextLabels == ["Work", "Moving house"])
    }

    /// A newer version may add words; until this one knows them, they're left out rather than shown wrong.
    @Test
    func `a check-in skips words this version doesn't know`() {
        let checkIn = CheckIn(CheckInAnswer(pleasantness: .neutral, feelings: [.calm]))

        checkIn.feelingIDs.append("feeling.addedLater")

        #expect(checkIn.feelings == [.calm])
    }

    /// A newer version may add a step to the scale; until this one knows it, the check-in has none rather than failing
    /// to load.
    @Test
    func `a check-in from a step this version doesn't know has no pleasantness`() throws {
        let checkIn = CheckIn(CheckInAnswer(pleasantness: .neutral, feelings: [.calm]))
        checkIn.pleasantnessID = "addedLater"

        let reader = try save(checkIn)
        let fetched = try #require(try reader.fetch(FetchDescriptor<CheckIn>()).only)

        #expect(fetched.pleasantness == nil)
        #expect(fetched.feelings == [.calm])
    }

    /// A newer version may add a tool; until this one knows it, the run has no tool rather than failing to load.
    @Test
    func `a tool session from a tool this version doesn't know has no tool`() throws {
        let session = ToolSession(tool: .breathe)
        session.toolID = "addedLater"

        let reader = try save(session)
        let fetched = try #require(try reader.fetch(FetchDescriptor<ToolSession>()).only)

        #expect(fetched.tool == nil)
    }

    /// A newer version may add an answer; until this one knows it, the run counts as unanswered rather than failing
    /// to load.
    @Test
    func `a tool session with an answer this version doesn't know has no outcome`() throws {
        let session = ToolSession(tool: .breathe)
        session.outcomeID = "addedLater"

        let reader = try save(session)
        let fetched = try #require(try reader.fetch(FetchDescriptor<ToolSession>()).only)

        #expect(fetched.outcome == nil)
        #expect(fetched.tool == .breathe)
    }
}
