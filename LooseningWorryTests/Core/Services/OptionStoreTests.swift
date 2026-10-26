import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
struct OptionStoreTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
        context = ModelContext(container)
    }

    private func saved() throws -> [LoopOption] {
        try context.fetch(FetchDescriptor<LoopOption>())
    }

    @Test
    func `adding new text saves it as the person's own option`() throws {
        let choice = try OptionStore(context: context).addOwn("Rent due", kind: .trigger)

        let options = try saved()
        try #require(options.count == 1)
        let option = options[0]
        #expect(choice == OptionChoice(option))
        #expect(option.kind == .trigger)
        #expect(option.label == "Rent due")
        #expect(option.starterID == nil)
        #expect(option.isHidden == false)
    }

    @Test
    func `adding the text of a hidden option brings it back instead of saving a twin`() throws {
        let hidden = LoopOption(overriding: .news, label: "News")
        hidden.isHidden = true
        hidden.updatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        context.insert(hidden)
        let before = Date.now

        let choice = try OptionStore(context: context).addOwn("News", kind: .trigger)

        let options = try saved()
        try #require(options.count == 1)
        let option = options[0]
        // A starter brought back is counted as the starter.
        #expect(choice == OptionChoice(.news, label: "News"))
        #expect(option === hidden)
        #expect(option.isHidden == false)
        // Bringing it back is an edit, so it wins over older changes from other devices.
        #expect(option.updatedAt >= before)
    }

    /// The note under the field promises the option is kept, even if the loop is never saved.
    @Test
    func `an added option is saved straight away`() throws {
        _ = try OptionStore(context: context).addOwn("Rent due", kind: .trigger)

        let elsewhere = ModelContext(container)
        #expect(try elsewhere.fetch(FetchDescriptor<LoopOption>()).map(\.label) == ["Rent due"])
    }

    @Test
    func `a hidden option of the person's own comes back first in the list, like a new one`() throws {
        let hidden = LoopOption(kind: .trigger, label: "Rent due")
        hidden.isHidden = true
        hidden.createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = LoopOption(kind: .trigger, label: "Call from Mom")
        newer.createdAt = Date(timeIntervalSince1970: 1_700_100_000)
        context.insert(hidden)
        context.insert(newer)

        let choice = try OptionStore(context: context).addOwn("Rent due", kind: .trigger)

        let options = try saved()
        // One of their own brought back keeps its id, so its history carries on.
        #expect(choice.id == hidden.optionID)
        #expect(options.count == 2)
        #expect(hidden.isHidden == false)
        #expect(OptionList.choices(for: .trigger, saved: options).first?.label == "Rent due")
    }

    /// Step 3 lists the person's results in the order they were added, so one that comes back keeps its place.
    @Test
    func `a hidden result of the person's own comes back in its old place`() throws {
        let hidden = LoopOption(kind: .result, label: "Felt silly")
        hidden.isHidden = true
        hidden.createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = LoopOption(kind: .result, label: "Got a headache")
        newer.createdAt = Date(timeIntervalSince1970: 1_700_100_000)
        context.insert(hidden)
        context.insert(newer)

        _ = try OptionStore(context: context).addOwn("Felt silly", kind: .result)

        let custom = try OptionList.choices(for: .result, saved: saved()).filter { $0.starterID == nil }
        #expect(custom.map(\.label) == ["Felt silly", "Got a headache"])
    }

    /// Each change to a starter is its own row, and only the newest one says how it shows.
    @Test
    func `a starter hidden after an earlier change comes back in its place, from its newest change`() throws {
        let restore = LoopOption(overriding: .news, label: "News")
        restore.updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let hide = LoopOption(overriding: .news, label: "News")
        hide.isHidden = true
        hide.updatedAt = Date(timeIntervalSince1970: 1_700_100_000)
        context.insert(restore)
        context.insert(hide)

        _ = try OptionStore(context: context).addOwn("News", kind: .trigger)

        let options = try saved()
        #expect(options.count == 2)
        #expect(hide.isHidden == false)
        let choices = OptionList.choices(for: .trigger, saved: options)
        #expect(choices.filter { $0.label == "News" } == [OptionChoice(.news, label: "News")])
        #expect(choices.map(\.starterID) == StarterOption.options(for: .trigger).map(\.id))
    }

    // MARK: - Remove and restore

    private func shown(_ kind: OptionKind) throws -> [OptionChoice] {
        try OptionList.choices(for: kind, saved: saved())
    }

    @Test
    func `removing the person's own option hides it`() throws {
        let rent = LoopOption(kind: .trigger, label: "Rent due")
        context.insert(rent)
        let before = Date.now

        try OptionStore(context: context).remove(OptionChoice(rent))

        #expect(rent.isHidden)
        #expect(rent.updatedAt >= before)
        #expect(try !shown(.trigger).contains { $0.label == "Rent due" })
    }

    /// Hiding keeps the full text, so typing it again in the logger brings the starter back.
    @Test
    func `removing a starter saves a change that hides it, with its text`() throws {
        try OptionStore(context: context).remove(OptionChoice(.news, label: "News"))

        let override = try #require(try saved().only)
        #expect(override.starter == .news)
        #expect(override.isHidden)
        #expect(override.label == "News")
        #expect(try !shown(.trigger).contains { $0.starterID == .news })
    }

    /// Step 3's core results stay, so the scale always reads the same.
    @Test
    func `a core result can't be removed`() throws {
        #expect(throws: OptionStore.EditError.coreResult) {
            try OptionStore(context: context).remove(OptionChoice(.notSure, label: "Not sure"))
        }
        #expect(try saved().isEmpty)
    }

    /// The list shows a text once, so removing it removes every option showing it.
    @Test
    func `removing a choice hides every copy of its text`() throws {
        let first = LoopOption(kind: .trigger, label: "Rent due")
        first.createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let second = LoopOption(kind: .trigger, label: "Rent due")
        context.insert(first)
        context.insert(second)
        let choice = try #require(try shown(.trigger).first { $0.label == "Rent due" })

        try OptionStore(context: context).remove(choice)

        #expect(first.isHidden)
        #expect(second.isHidden)
    }

    @Test
    func `a removed option can be restored`() throws {
        let store = OptionStore(context: context)
        let rent = LoopOption(kind: .trigger, label: "Rent due")
        context.insert(rent)
        try store.remove(OptionChoice(rent))
        try store.remove(OptionChoice(.news, label: "News"))

        let removed = try OptionList.removedChoices(for: .trigger, saved: saved())
        for choice in removed {
            try store.restore(choice, kind: .trigger)
        }

        let starters = StarterOption.options(for: .trigger).map(\.id)
        #expect(try shown(.trigger).compactMap(\.starterID) == starters)
        #expect(try shown(.trigger).contains { $0.label == "Rent due" })
        #expect(try OptionList.removedChoices(for: .trigger, saved: saved()).isEmpty)
    }

    /// Restoring would put the same text in the list twice.
    @Test
    func `an option can't be restored while another shows its text`() throws {
        let store = OptionStore(context: context)
        let old = LoopOption(kind: .trigger, label: "Rent due")
        context.insert(old)
        try store.remove(OptionChoice(old))
        context.insert(LoopOption(kind: .trigger, label: "Rent due"))
        let removed = try #require(try OptionList.removedChoices(for: .trigger, saved: saved()).only)

        #expect(throws: OptionStore.EditError.alreadyShowing) {
            try store.restore(removed, kind: .trigger)
        }
        #expect(old.isHidden)
    }

    /// Options can't be renamed, but an override saved by an older build may carry other text. Hiding stores the
    /// starter's own words, so typing them in the logger brings it back.
    @Test
    func `hiding a starter stores its own words, whatever its last change said`() throws {
        context.insert(LoopOption(overriding: .news, label: "World news"))

        try OptionStore(context: context).remove(OptionChoice(.news, label: "News"))

        let override = try #require(try saved().only)
        #expect(override.isHidden)
        #expect(override.label == "News")
        #expect(try OptionList.hiddenOption(matching: "News", for: .trigger, saved: saved()) === override)
    }
}
