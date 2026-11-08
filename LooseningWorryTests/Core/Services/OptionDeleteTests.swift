import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

/// Deleting the person's own removed options for good, and adding their text again later.
@MainActor
struct OptionDeleteTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
        context = ModelContext(container)
    }

    private var store: OptionStore {
        OptionStore(context: context)
    }

    private func saved() throws -> [LoopOption] {
        try context.fetch(FetchDescriptor<LoopOption>())
    }

    /// The person's own option, added and then removed, as the Removed list shows it.
    private func removed(_ label: String, kind: OptionKind = .trigger) throws -> OptionChoice {
        let choice = try store.addOwn(label, kind: kind)
        try store.remove(choice)
        return try #require(OptionList.removedChoices(for: kind, saved: saved()).first { $0.label == label })
    }

    @Test
    func `deleting a removed option of the person's own erases every copy`() throws {
        _ = try removed("Rent due")
        // A copy synced from another device, removed there too.
        let copy = LoopOption(kind: .trigger, label: "Rent due")
        copy.isHidden = true
        context.insert(copy)
        let choice = try #require(OptionList.removedChoices(for: .trigger, saved: saved()).first)
        #expect(choice.allIDs.count == 2)

        try store.delete(choice)

        #expect(try saved().isEmpty)
        #expect(try OptionList.removedChoices(for: .trigger, saved: saved()).isEmpty)
    }

    /// Starters live in code, so they can only be hidden.
    @Test
    func `a starter can't be deleted, only hidden`() throws {
        let news = OptionChoice(.news, label: "News")
        try store.remove(news)

        #expect(throws: OptionStore.EditError.starter) { try store.delete(news) }
        #expect(try OptionList.removedChoices(for: .trigger, saved: saved()).map(\.id) == ["trigger.news"])
    }

    @Test
    func `adding a deleted option's text again counts its past loops with it`() throws {
        let rentDue = try store.addOwn("Rent due", kind: .trigger)
        let loop = Loop(trigger: rentDue, behavior: .scrolled, result: .moreWorry)
        context.insert(loop)
        try store.remove(rentDue)
        try store.delete(rentDue)
        #expect(loop.triggerLabel == "Rent due")

        let again = try store.addOwn("Rent due", kind: .trigger)

        #expect(again.allIDs.contains(loop.triggerID))
        let shown = try OptionList.choices(for: .trigger, saved: saved()).filter { $0.label == "Rent due" }
        #expect(shown.count == 1)
        #expect(shown.first?.allIDs.contains(loop.triggerID) == true)
    }

    /// A loop's behavior and its trigger are different answers, even with the same text.
    @Test
    func `a deleted behavior's text doesn't merge into a new trigger`() throws {
        let work = try store.addOwn("Work late", kind: .behavior)
        context.insert(Loop(trigger: .news, behavior: work, result: .moreWorry))
        try store.remove(work)
        try store.delete(work)

        let trigger = try store.addOwn("Work late", kind: .trigger)

        #expect(trigger.id != work.id)
    }

    @Test
    func `adding a deleted context's text again counts its past check-ins with it`() throws {
        let moving = try store.addOwn("Moving house", kind: .context)
        let checkIn = CheckIn(CheckInAnswer(pleasantness: .unpleasant, feelings: [], contexts: [moving]))
        context.insert(checkIn)
        try store.remove(moving)
        try store.delete(moving)

        let again = try store.addOwn("Moving house", kind: .context)

        #expect(again.allIDs.contains(moving.id))
        #expect(checkIn.contextLabels == ["Moving house"])
    }

    /// A loop met with a tool stores the tool and how it went under ids of their own, which no option holds. Taking
    /// one would count the person's own habit as the tool, so only ids made for options of their own are taken.
    @Test
    func `the person's own option never takes a tool's or its outcome's id`() throws {
        let breathed = QuickTool.breathe.asBehavior
        let lighter = ToolOutcome.lighter.asResult
        context.insert(Loop(trigger: .news, behavior: breathed, result: lighter))

        let behavior = try store.addOwn(breathed.label, kind: .behavior)
        let result = try store.addOwn(lighter.label, kind: .result)

        #expect(behavior.id != breathed.id)
        #expect(result.id != lighter.id)
    }

    /// Two devices that each add a deleted option's text again each make a row under its old id, and sync brings both
    /// together; the list shows them as one, so removing and restoring it must reach both.
    @Test
    func `removing and restoring reach every row that shares an id`() throws {
        let original = try store.addOwn("Rent due", kind: .trigger)
        let twin = LoopOption(kind: .trigger, label: "Rent due")
        twin.optionID = original.id
        context.insert(twin)

        try store.remove(original)
        #expect(try saved().allSatisfy(\.isHidden))

        try store.restore(original, kind: .trigger)
        #expect(try saved().allSatisfy { !$0.isHidden })
    }

    @Test
    func `text with spaces around it merges like the text itself`() throws {
        let rentDue = try store.addOwn("Rent due", kind: .trigger)
        context.insert(Loop(trigger: rentDue, behavior: .scrolled, result: .moreWorry))
        try store.remove(rentDue)
        try store.delete(rentDue)

        let again = try store.addOwn("  Rent due ", kind: .trigger)

        #expect(again == OptionChoice(id: rentDue.id, label: "Rent due"))
    }

    /// Only a deleted option's id comes back: one an option still has stays with it.
    @Test
    func `an id still held by an option is never taken again`() throws {
        let rentDue = try store.addOwn("Rent due", kind: .trigger)
        context.insert(Loop(trigger: rentDue, behavior: .scrolled, result: .moreWorry))

        let twin = try store.addOwn("Rent due", kind: .trigger)

        #expect(twin.id != rentDue.id)
    }
}
