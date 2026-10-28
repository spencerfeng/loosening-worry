import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
struct PhraseStoreTests {
    private let container: ModelContainer
    private let start = Date(timeIntervalSince1970: 1_793_000_000)

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
    }

    private var store: PhraseStore {
        PhraseStore(context: container.mainContext)
    }

    @Test
    func `a kept phrase reads back, newest first`() throws {
        try store.keep("This is hard right now.", now: start)
        try store.keep("I can be gentle with myself.", now: start.addingTimeInterval(60))

        #expect(try store.phrases().map(\.text) == ["I can be gentle with myself.", "This is hard right now."])
    }

    /// The person's own words are kept as written, less the spaces around them; there's nothing to keep in a blank.
    @Test
    func `own words are kept trimmed, and a blank isn't kept`() throws {
        try store.keep("  It's okay to find this hard.\n", now: start)
        try store.keep("   ", now: start)

        #expect(try store.phrases().map(\.text) == ["It's okay to find this hard."])
    }

    @Test
    func `keeping the same words again keeps them once`() throws {
        try store.keep("This is hard right now.", now: start)
        try store.keep("This is hard right now.", now: start.addingTimeInterval(60))

        #expect(try store.phrases().count == 1)
        #expect(try store.isKept("This is hard right now."))
    }

    @Test
    func `a phrase can be let go of`() throws {
        try store.keep("This is hard right now.", now: start)

        try store.remove("This is hard right now.")

        #expect(try store.phrases().isEmpty)
        #expect(try store.isKept("This is hard right now.") == false)
    }

    /// Two devices can each keep the same words before they sync; the person still sees them once.
    @Test
    func `copies of the same words synced from another device read back once`() throws {
        container.mainContext.insert(KeptPhrase(text: "This is hard right now.", keptAt: start))
        container.mainContext.insert(KeptPhrase(text: "This is hard right now.", keptAt: start.addingTimeInterval(5)))
        try container.mainContext.save()

        #expect(try store.phraseTexts() == ["This is hard right now."])

        try store.remove("This is hard right now.")
        #expect(try store.phrases().isEmpty)
    }
}
