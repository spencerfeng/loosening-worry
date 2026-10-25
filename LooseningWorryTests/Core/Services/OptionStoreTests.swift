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
        try OptionStore(context: context).addOwn("Rent due", kind: .trigger)

        let options = try saved()
        try #require(options.count == 1)
        let option = options[0]
        #expect(option.kind == .trigger)
        #expect(option.label == "Rent due")
        #expect(option.starterID == nil)
        #expect(option.isHidden == false)
    }

    @Test
    func `adding the text of a hidden option brings it back instead of saving a twin`() throws {
        let hidden = LoopOption(overriding: .news, label: "World news")
        hidden.isHidden = true
        hidden.updatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        context.insert(hidden)
        let before = Date.now

        try OptionStore(context: context).addOwn("World news", kind: .trigger)

        let options = try saved()
        try #require(options.count == 1)
        let option = options[0]
        #expect(option === hidden)
        #expect(option.isHidden == false)
        // Bringing it back is an edit, so it wins over older changes from other devices.
        #expect(option.updatedAt >= before)
    }

    /// The note under the field promises the option is kept, even if the loop is never saved.
    @Test
    func `an added option is saved straight away`() throws {
        try OptionStore(context: context).addOwn("Rent due", kind: .trigger)

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

        try OptionStore(context: context).addOwn("Rent due", kind: .trigger)

        let options = try saved()
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

        try OptionStore(context: context).addOwn("Felt silly", kind: .result)

        let custom = try OptionList.choices(for: .result, saved: saved()).filter { $0.starterID == nil }
        #expect(custom.map(\.label) == ["Felt silly", "Got a headache"])
    }

    /// Each change to a starter is its own row, and only the newest one says how it shows.
    @Test
    func `a starter hidden after an earlier change comes back in its place, from its newest change`() throws {
        let rename = LoopOption(overriding: .news, label: "Headlines")
        rename.updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let hide = LoopOption(overriding: .news, label: "World news")
        hide.isHidden = true
        hide.updatedAt = Date(timeIntervalSince1970: 1_700_100_000)
        context.insert(rename)
        context.insert(hide)

        try OptionStore(context: context).addOwn("World news", kind: .trigger)

        let options = try saved()
        #expect(options.count == 2)
        #expect(hide.isHidden == false)
        let choices = OptionList.choices(for: .trigger, saved: options)
        #expect(choices.filter { $0.label == "World news" } == [
            OptionChoice(.news, label: "World news")
        ])
        #expect(choices.map(\.starterID) == StarterOption.options(for: .trigger).map(\.id))
    }
}
