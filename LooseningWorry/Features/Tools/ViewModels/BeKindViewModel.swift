import Foundation
import Observation
import os

/// Be kind: the person goes through the pages at their own pace, finishing on the last. On a phrase page they can try
/// other wordings until one rings true, and keep any phrase, or their own words, to read again. Someone with phrases
/// kept chooses first between going through it and reading them.
@Observable @MainActor
final class BeKindViewModel {
    enum Mode {
        /// With phrases kept: going through the pages, or reading them.
        case choosing
        /// Going through the pages.
        case steps
        /// Reading the phrases kept before.
        case reading
    }

    let run: ToolRunViewModel
    private(set) var mode = Mode.steps
    private(set) var page = KindPage.notice
    /// What the person would say to a friend, if they write it.
    var ownWords = ""
    /// The words that couldn't be kept or let go of just now; the screen says so beside them.
    private(set) var failedToKeep: String?
    /// The words the person has kept, newest first.
    private(set) var keptPhrases: [String] = []
    /// What "Your phrases" lists: the kept phrases as they were when it opened, so one let go of stays, to keep again.
    private(set) var readingList: [String] = []
    /// The take-away as its page opened, so letting go of it doesn't swap it for another while it's being read.
    private(set) var shownTakeAway = ""

    private let store: any PhraseKeeping
    /// Which wording each phrase page shows, by its place in the page's wordings.
    private var wordingIndex: [KindPage: Int] = [:]
    /// What was kept this time, in order, for the take-away.
    private var keptThisTime: [String] = []

    /// With phrases kept from before, it opens on the choice of reading them; otherwise on the first page.
    init(run: ToolRunViewModel, store: any PhraseKeeping) {
        self.run = run
        self.store = store
        readKept()
        mode = keptPhrases.isEmpty ? .steps : .choosing
    }

    var isFirstPage: Bool {
        page == KindPage.allCases.first
    }

    var isLastPage: Bool {
        page == KindPage.allCases.last
    }

    /// "Page 3 of 7", counting from 1.
    var pageNumber: Int {
        (KindPage.allCases.firstIndex(of: page) ?? 0) + 1
    }

    var pageCount: Int {
        KindPage.allCases.count
    }

    func goThrough() {
        readKept()
        mode = .steps
        page = .notice
    }

    func readPhrases() {
        run.markEngaged()
        readKept()
        readingList = keptPhrases
        mode = .reading
    }

    /// "Something to take with you": the person's own words if they wrote some, else the phrase they last kept this
    /// time, else the kindness wording they chose.
    var takeAway: String {
        let own = Self.trimmed(ownWords)
        if !own.isEmpty {
            return own
        }
        if let kept = keptThisTime.last {
            return kept
        }
        return phraseText(on: .kindness) ?? ""
    }

    /// The wording a phrase page shows: the plainest until the person tries others.
    func wording(on page: KindPage) -> KindWording? {
        let wordings = page.wordings
        guard !wordings.isEmpty else { return nil }
        return wordings[(wordingIndex[page] ?? 0) % wordings.count]
    }

    /// The words a phrase page shows, as they'd be kept.
    func phraseText(on page: KindPage) -> String? {
        wording(on: page).map { String(localized: $0.text) }
    }

    /// "Try other words": the page's next wording, round to the first again.
    func tryOtherWords() {
        guard !page.wordings.isEmpty else { return }
        wordingIndex[page, default: 0] += 1
    }

    var canKeepOwnWords: Bool {
        !Self.trimmed(ownWords).isEmpty
    }

    func isKept(_ text: String) -> Bool {
        keptPhrases.contains(Self.trimmed(text))
    }

    /// Keeps `text`, or lets it go if it's kept already.
    func toggleKeep(_ text: String, now: Date) {
        let text = Self.trimmed(text)
        guard !text.isEmpty else { return }
        do {
            if keptPhrases.contains(text) {
                try store.remove(text)
                keptPhrases.removeAll { $0 == text }
                keptThisTime.removeAll { $0 == text }
            } else {
                try store.keep(text, now: now)
                keptPhrases.insert(text, at: 0)
                keptThisTime.append(text)
            }
            failedToKeep = nil
        } catch {
            Self.logger.error("Couldn't keep or let go of a phrase: \(error)")
            failedToKeep = text
        }
    }

    /// Next; turning past the first page makes this a session.
    func next() {
        run.markEngaged()
        move(by: 1)
    }

    /// Back, or from the first page, back to the choice for someone who came from it.
    func back() {
        if isFirstPage, !keptPhrases.isEmpty {
            mode = .choosing
        } else {
            move(by: -1)
        }
    }

    /// Finish, on the last page or after reading: on to "How do you feel now?".
    func finish(now: Date) {
        run.end(now: now)
    }

    private func move(by step: Int) {
        let pages = KindPage.allCases
        guard let index = pages.firstIndex(of: page) else { return }
        page = pages[min(max(index + step, 0), pages.count - 1)]
        if page == .takeAway {
            shownTakeAway = takeAway
        }
    }

    /// Reads the kept phrases again, as some may have arrived from the person's other devices.
    private func readKept() {
        do {
            keptPhrases = try store.phraseTexts()
        } catch {
            Self.logger.error("Couldn't read the kept phrases: \(error)")
        }
    }

    private static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Tools")
}
