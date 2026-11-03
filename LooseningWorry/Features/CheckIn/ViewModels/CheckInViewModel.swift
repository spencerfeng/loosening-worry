import Foundation
import Observation
import os

/// One check-in: how it feels overall, then the words that describe it, then what to try.
@Observable
@MainActor
final class CheckInViewModel {
    enum Step: Equatable {
        case pleasantness, feelings
        /// Saved, with what the finish screen offers.
        case finished(CheckInSuggestion)
    }

    private(set) var step = Step.pleasantness
    /// Step 1's answer, once chosen.
    private(set) var pleasantness: Pleasantness?
    /// Step 2's words, in the order they were picked.
    private(set) var feelings: [Feeling] = []
    /// The last try at saving failed; step 2 says so, and Done tries again.
    private(set) var saveFailed = false

    /// What the finish screen offers, once the check-in is saved.
    var suggestion: CheckInSuggestion? {
        if case let .finished(suggestion) = step {
            suggestion
        } else {
            nil
        }
    }

    /// Step 2's words: those that fit step 1's answer first, the rest under More. Empty until step 1 is answered.
    var groupedFeelings: (first: [Feeling], more: [Feeling]) {
        guard let pleasantness else { return ([], []) }
        return Feeling.grouped(for: pleasantness)
    }

    /// The finish screen's chips: how it felt overall, then each word in the order picked.
    var summary: [LocalizedStringResource] {
        (pleasantness.map { [$0.label] } ?? []) + feelings.map(\.label)
    }

    /// The finish screen's line under the chips, once step 1 is answered. Drafts for the reviewer.
    var closingLine: LocalizedStringResource? {
        switch pleasantness?.side {
        case .unpleasant:
            LocalizedStringResource(
                "checkIn.done.unpleasant",
                defaultValue: "Thanks for naming it. That alone gives you a little space from it.",
            )
        case .neutral:
            LocalizedStringResource(
                "checkIn.done.neutral",
                defaultValue: "Noticing how you are, whatever it is, is the practice.",
            )
        case .pleasant:
            LocalizedStringResource(
                "checkIn.done.pleasant",
                defaultValue: "Noticing a good moment counts too. Your brain learns from what feels good.",
            )
        case nil: nil
        }
    }

    /// Picks step 1's answer; it can be changed until the check-in is saved.
    func choose(_ pleasantness: Pleasantness) {
        self.pleasantness = pleasantness
    }

    /// Picks `feeling`, or unpicks it if it's already picked.
    func toggle(_ feeling: Feeling) {
        if let index = feelings.firstIndex(of: feeling) {
            feelings.remove(at: index)
        } else {
            feelings.append(feeling)
        }
    }

    /// From step 1 to step 2, once step 1 is answered.
    func next() {
        guard step == .pleasantness, pleasantness != nil else { return }
        step = .feelings
    }

    /// Step 2's Done: saves the check-in through `store`, then shows the finish screen. If `store` throws, it stays
    /// on step 2 with `saveFailed` set.
    func finish(_ store: (CheckIn) throws -> Void) {
        guard step == .feelings, let pleasantness else { return }
        let answer = CheckInAnswer(pleasantness: pleasantness, feelings: feelings)
        do {
            try store(CheckIn(answer))
        } catch {
            Self.logger.error("Couldn't save a check-in: \(error)")
            saveFailed = true
            return
        }
        saveFailed = false
        step = .finished(CheckInSuggestion(for: answer))
    }

    /// From step 2 back to step 1. The words picked stay picked; a failed save's note goes, as it belongs to Done.
    func back() {
        guard step == .feelings else { return }
        saveFailed = false
        step = .pleasantness
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "CheckIn")
}
