import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
final class BeKindViewModelTests {
    private let start = Date(timeIntervalSince1970: 1_793_000_000)
    /// Each test gets its own defaults and an in-memory store, so nothing leaks between tests or into the app.
    private let suiteName = "BeKindViewModelTests.\(UUID().uuidString)"
    private let run: ToolRunViewModel
    private let container: ModelContainer

    init() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        run = ToolRunViewModel(
            tool: .beKind,
            now: start,
            picker: PromptPicker(defaults: defaults, prompts: .empty),
            lengths: ToolLengths(defaults: defaults),
        )
        container = try AppModelContainer.make(inMemory: true)
    }

    isolated deinit {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    private var store: PhraseStore {
        PhraseStore(context: container.mainContext)
    }

    private func model() -> BeKindViewModel {
        BeKindViewModel(run: run, store: store)
    }

    @Test
    func `with nothing kept, it opens on the first page`() {
        let model = model()

        #expect(model.mode == .steps)
        #expect(model.page == .notice)
        #expect(model.isFirstPage)
    }

    @Test
    func `next and back move through the pages, stopping at the ends`() {
        let model = model()

        model.back()
        #expect(model.page == .notice)

        model.next()
        model.next()
        #expect(model.page == .hard)

        model.back()
        #expect(model.page == .touch)

        for _ in 0 ..< 10 {
            model.next()
        }
        #expect(model.page == .takeAway)
        #expect(model.isLastPage)
    }

    @Test
    func `finish ends the run with the time spent`() {
        let model = model()

        model.finish(now: start.addingTimeInterval(75))

        #expect(run.stage == .finished)
        #expect(run.elapsed == .seconds(75))
    }

    /// Kind words can feel untrue at first, so the person can look for a wording that rings true.
    @Test
    func `other words cycle through a phrase page's wordings, and the choice stays`() {
        let model = model()
        model.next()
        model.next()
        #expect(model.wording(on: .hard) == .thisIsHard)

        model.tryOtherWords()
        model.tryOtherWords()
        #expect(model.wording(on: .hard) == .makesSense)

        model.next()
        model.back()
        #expect(model.wording(on: .hard) == .makesSense)

        model.tryOtherWords()
        #expect(model.wording(on: .hard) == .thisIsHard)
    }

    @Test
    func `keeping the phrase shown saves its words, and again lets it go`() throws {
        let model = model()

        model.toggleKeep("This is hard right now.", now: start)
        #expect(model.isKept("This is hard right now."))
        #expect(try store.phrases().map(\.text) == ["This is hard right now."])

        model.toggleKeep("This is hard right now.", now: start)
        #expect(model.isKept("This is hard right now.") == false)
        #expect(try store.phrases().isEmpty)
    }

    @Test
    func `the person's own words can be kept, but not a blank`() throws {
        let model = model()
        model.ownWords = "   "
        #expect(model.canKeepOwnWords == false)

        model.ownWords = " It's okay to find this hard. "
        model.toggleKeep(model.ownWords, now: start)

        #expect(model.canKeepOwnWords)
        #expect(try store.phrases().map(\.text) == ["It's okay to find this hard."])
        #expect(model.isKept(model.ownWords))
    }

    /// The take-away is the person's own words if they wrote some, else what they kept, else their kindness wording.
    @Test
    func `the take-away is the kindness wording chosen, when nothing else was kept or written`() {
        let model = model()
        #expect(model.takeAway == "May I be kind to myself right now.")

        for _ in 0 ..< 4 {
            model.next()
        }
        model.tryOtherWords()

        #expect(model.takeAway == "I can be gentle with myself.")
    }

    @Test
    func `the take-away is the phrase last kept this time`() {
        let model = model()

        model.toggleKeep("Lots of people feel this way.", now: start)
        model.toggleKeep("This is hard right now.", now: start.addingTimeInterval(5))
        #expect(model.takeAway == "This is hard right now.")

        model.toggleKeep("This is hard right now.", now: start.addingTimeInterval(9))
        #expect(model.takeAway == "Lots of people feel this way.")
    }

    @Test
    func `the take-away is the person's own words, when they wrote some`() {
        let model = model()
        model.toggleKeep("Lots of people feel this way.", now: start)

        model.ownWords = " It's okay to find this hard. "

        #expect(model.takeAway == "It's okay to find this hard.")
    }

    /// Kind words that helped before are the fastest way back to kindness, so they're offered first.
    @Test
    func `with phrases kept, it opens on a choice between going through it and reading them`() throws {
        try store.keep("This is hard right now.", now: start)
        try store.keep("It's okay to find this hard.", now: start.addingTimeInterval(60))
        let model = model()
        #expect(model.mode == .choosing)

        model.readPhrases()
        #expect(model.mode == .reading)
        #expect(model.keptPhrases == ["It's okay to find this hard.", "This is hard right now."])

        model.toggleKeep("This is hard right now.", now: start)
        #expect(model.keptPhrases == ["It's okay to find this hard."])
    }

    @Test
    func `going through it from the choice starts on the first page`() throws {
        try store.keep("This is hard right now.", now: start)
        let model = model()

        model.goThrough()

        #expect(model.mode == .steps)
        #expect(model.page == .notice)
    }

    @Test
    func `other words do nothing on a page without wordings`() {
        let model = model()

        model.tryOtherWords()

        #expect(model.page == .notice)
        #expect(model.wording(on: .notice) == nil)
    }

    /// VoiceOver says where the person is among the pages.
    @Test
    func `the model says which page of how many`() {
        let model = model()
        model.next()
        model.next()

        #expect(model.pageNumber == 3)
        #expect(model.pageCount == 7)
    }

    /// Letting go of the take-away mustn't swap it for another phrase while the person is reading it.
    @Test
    func `the take-away stays as shown once its page opens`() {
        let model = model()
        model.toggleKeep("Lots of people feel this way.", now: start)
        model.toggleKeep("This is hard right now.", now: start)
        for _ in 0 ..< 6 {
            model.next()
        }
        #expect(model.shownTakeAway == "This is hard right now.")

        model.toggleKeep("This is hard right now.", now: start)

        #expect(model.shownTakeAway == "This is hard right now.")
        #expect(model.isKept("This is hard right now.") == false)
    }

    @Test
    func `back from the first page returns to the choice, for someone who came from it`() throws {
        try store.keep("This is hard right now.", now: start)
        let model = model()
        model.goThrough()

        model.back()

        #expect(model.mode == .choosing)
    }

    /// Letting go while reading keeps the phrase in the list, so it can be kept again, and nothing empties the page.
    @Test
    func `a phrase let go of while reading stays listed, to keep again`() throws {
        try store.keep("This is hard right now.", now: start)
        let model = model()
        model.readPhrases()

        model.toggleKeep("This is hard right now.", now: start)
        #expect(model.readingList == ["This is hard right now."])
        #expect(model.isKept("This is hard right now.") == false)

        model.toggleKeep("This is hard right now.", now: start)
        #expect(model.isKept("This is hard right now."))
    }

    /// Phrases can arrive from the person's other devices while Be kind is open.
    @Test
    func `the kept phrases are read again when the person opens them`() throws {
        try store.keep("This is hard right now.", now: start)
        let model = model()
        try store.keep("I'm not alone in this.", now: start.addingTimeInterval(60))

        model.readPhrases()

        #expect(model.readingList == ["I'm not alone in this.", "This is hard right now."])
    }

    @Test
    func `a phrase that couldn't be kept is marked, and only that one`() {
        let model = BeKindViewModel(run: run, store: FailingPhraseStore())

        model.toggleKeep("This is hard right now.", now: start)

        #expect(model.failedToKeep == "This is hard right now.")
        #expect(model.isKept("This is hard right now.") == false)
    }
}

/// A phrase store whose saves always fail, as when the device is out of space.
@MainActor
private struct FailingPhraseStore: PhraseKeeping {
    struct Failed: Error {}

    func keep(_: String, now _: Date) throws {
        throw Failed()
    }

    func remove(_: String) throws {
        throw Failed()
    }

    func phraseTexts() throws -> [String] {
        []
    }
}
