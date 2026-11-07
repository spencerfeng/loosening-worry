import Foundation
import Observation
import os

/// One check-in: how it feels overall, the words that describe it, and what's having the biggest impact, then what to
/// try.
@Observable
@MainActor
final class CheckInViewModel {
    enum Step: Equatable {
        case pleasantness, feelings, contexts
        /// Saved, with what the finish screen offers.
        case finished(CheckInSuggestion)
    }

    private(set) var step = Step.pleasantness
    /// Step 1's answer, once chosen.
    private(set) var pleasantness: Pleasantness?
    /// Step 2's words, in the order they were picked.
    private(set) var feelings: [Feeling] = []
    /// Step 3's contexts, in the order they were picked.
    private(set) var contexts: [OptionChoice] = []
    /// Step 3's "+ Add your own" field.
    var ownDraft = AddOwnDraft()
    /// The last try at saving failed; step 3 says so, and Done tries again.
    private(set) var saveFailed = false
    /// Whether step 2 shows the words under More: once More is tapped, until the person goes back.
    private(set) var showsMoreFeelings = false
    /// The choices step 3 shows from the person's list, as `showContextChoices` last gave them.
    private var contextChoices: [OptionChoice] = []
    /// Contexts the person added that couldn't be saved to their list. Step 3 still shows them for the rest of the
    /// check-in, picked or not, since they aren't among its choices.
    private var unsavedContexts: [OptionChoice] = []

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

    /// The finish screen's chips: how it felt overall, then each word and each context in the order picked.
    var summary: [String] {
        (pleasantness.map { [$0.label] } ?? []).map { String(localized: $0) }
            + feelings.map { String(localized: $0.label) }
            + contexts.map(\.label)
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

    /// Step 2's More: shows the rest of the words until the person goes back.
    func showMoreFeelings() {
        showsMoreFeelings = true
    }

    /// Step 3's chips: its choices, with the contexts that couldn't be saved placed among them alphabetically.
    var contextChips: [OptionChoice] {
        OptionList.alphabetical(unsavedContexts + contextChoices)
    }

    /// Takes the choices step 3 shows from the person's list, whenever it changes. An unsaved context whose text a
    /// choice now shows, such as one synced from another device, gives way to that choice, picked if it was, so the
    /// text never shows twice. A picked context no chip shows any more, such as one removed on the Edit screen, is
    /// unpicked.
    func showContextChoices(_ choices: [OptionChoice]) {
        contextChoices = choices
        for unsaved in unsavedContexts {
            guard let saved = OptionList.match(unsaved.label, in: choices) else { continue }
            unsavedContexts.removeAll { $0.id == unsaved.id }
            if let place = contexts.firstIndex(where: { $0.id == unsaved.id }) {
                contexts.remove(at: place)
                if !isPicked(saved) {
                    contexts.insert(saved, at: place)
                }
            }
        }
        let shown = Set(contextChips.flatMap(\.allIDs))
        contexts.removeAll { !shown.contains($0.id) }
    }

    /// Whether `context` is picked, under any id its choice shows.
    func isPicked(_ context: OptionChoice) -> Bool {
        contexts.contains { context.allIDs.contains($0.id) }
    }

    /// Picks `context`, or unpicks it if it's already picked.
    func toggle(_ context: OptionChoice) {
        if isPicked(context) {
            contexts.removeAll { context.allIDs.contains($0.id) }
        } else {
            contexts.append(context)
        }
    }

    /// Picks `context` unless it's picked already, such as one the person just added on the Edit screen.
    func pick(_ context: OptionChoice) {
        if !isPicked(context) {
            contexts.append(context)
        }
    }

    /// Saves the draft as the person's own context and picks it, as `AddOwnDraft.take` does. Text matching a chip
    /// step 3 shows, one that couldn't be saved included, picks that chip instead.
    /// - Parameter save: Stores a new context, given its text, and returns the choice to pick. If it throws, the text
    ///   is still picked, and the draft's `unsavedLabel` tells the person it wasn't kept for next time.
    func addOwn(save: (String) throws -> OptionChoice) {
        guard let added = ownDraft.take(existing: contextChips, save: save) else { return }
        pick(added.choice)
        if !added.isSaved {
            unsavedContexts.append(added.choice)
            ownDraft.unsavedLabel = added.choice.label
        }
    }

    /// On to the next step, once step 1 is answered.
    func next() {
        switch step {
        case .pleasantness where pleasantness != nil: step = .feelings
        case .feelings: step = .contexts
        default: break
        }
    }

    /// Step 3's Done: saves the check-in through `store`, then shows the finish screen. If `store` throws, it stays
    /// on step 3 with `saveFailed` set.
    /// - Parameters:
    ///   - saveOwn: Saves text still typed in the field for the person's own context, so it's added and picked
    ///     rather than lost, as `addOwn` does. Without it, such text is left in the field.
    ///   - store: Saves the check-in.
    func finish(addingDraftWith saveOwn: ((String) throws -> OptionChoice)? = nil, _ store: (CheckIn) throws -> Void) {
        guard step == .contexts, let pleasantness else { return }
        if let saveOwn, ownDraft.isOpen {
            addOwn(save: saveOwn)
        }
        let answer = CheckInAnswer(pleasantness: pleasantness, feelings: feelings, contexts: contexts)
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

    /// Back one step, clearing what was picked on the step left, so it starts fresh if the person comes back to it.
    /// The earlier step keeps its answer. Leaving step 3 also drops a failed save's note, as it belongs to Done, and
    /// the field for the person's own context, with its draft.
    func back() {
        switch step {
        case .feelings:
            feelings = []
            showsMoreFeelings = false
            step = .pleasantness
        case .contexts:
            contexts = []
            saveFailed = false
            ownDraft.close()
            step = .feelings
        default: break
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "CheckIn")
}
