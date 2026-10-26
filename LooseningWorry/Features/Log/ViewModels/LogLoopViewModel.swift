import Foundation
import Observation
import os

/// Walks the person through a loop's three steps, trigger, behavior and result, one question at a time.
@Observable @MainActor
final class LogLoopViewModel {
    /// The step being asked, or `nil` once all three are answered.
    private(set) var currentStep: OptionKind? = .trigger
    private var answers: [OptionKind: OptionChoice] = [:]
    /// Cheers the step answered last; `nil` until the first pick.
    private(set) var cheer: LogCheer?
    /// How many loops the person logged before this one; set when the logger opens.
    var loopsLogged: Int
    /// Counts every pick, so the logger can replay its feedback even when a step is answered again.
    private(set) var pickCount = 0
    /// Whether the "+ Add your own" field is open for the current step.
    private(set) var isAddingOwn = false
    /// What the person has typed into that field.
    var draft = ""
    /// Text the person just added that was picked but couldn't be saved to their list; `nil` otherwise.
    private(set) var unsavedOption: String?
    /// Whether the optional details card is open.
    private(set) var isShowingDetails = false
    /// How anxious the person felt, 0–10, or `nil` until they set it: an untouched slider records nothing.
    private(set) var anxiety: Int?
    /// The optional note as typed.
    var note = ""
    /// What Nice catch shows, once the loop is saved.
    private(set) var niceCatch: NiceCatch?

    /// Whether the loop has been saved, so the logger moves on to Nice catch.
    var isSaved: Bool {
        niceCatch != nil
    }

    /// Whether the last try to save failed; the person's answers are kept so they can try again.
    private(set) var saveFailed = false

    /// Whether Save is offered: every step answered, none reopened, and not saved yet.
    var canSave: Bool {
        currentStep == nil && !isSaved
    }

    /// Whether the draft holds anything to add once spaces around it are trimmed.
    var canAddOwn: Bool {
        !trimmedDraft.isEmpty
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Loops from the last 90 days, read when the logger opens, that steps 1 and 2 are ordered by.
    var recentLoops: [Loop] = []
    /// Whether the current step shows all its choices rather than the first few and More.
    private(set) var isShowingAllChoices = false
    /// The order worked out when the current step opened. Not observed: it's filled in while the view reads the
    /// choices, and a change to it never needs a redraw.
    @ObservationIgnored private var stepOrder: StepOrder?
    private let pairs: StarterPairs

    /// How many choices steps 1 and 2 show before More.
    static let choicesBeforeMore = 6

    /// - Parameters:
    ///   - loopsLogged: How many loops the person logged before this one, so each new loop gets the next set of
    ///     cheers.
    ///   - pairs: The behaviors offered first after each starter trigger until the person has history of their own.
    init(loopsLogged: Int = 0, pairs: StarterPairs = .bundled) {
        self.loopsLogged = loopsLogged
        self.pairs = pairs
    }

    /// The step's choices in the order to offer them. Steps 1 and 2 follow the person's history, and step 2 the
    /// trigger they picked; step 3 keeps its fixed order. The order is worked out when the step opens, and for step 2
    /// again if the trigger changes, so the chips never shift under the person's finger: an option that arrives
    /// meanwhile, say synced from another device, joins at the end.
    func choices(for step: OptionKind, saved: [LoopOption]) -> [OptionChoice] {
        let choices = OptionList.choices(for: step, saved: saved)
        let trigger = step == .behavior ? answers[.trigger] : nil
        let key = StepOrder.Key(step: step, triggerID: trigger?.id)
        guard step != .result else { return choices }
        if stepOrder?.key != key {
            let ranker = OptionRanker(loops: recentLoops, saved: saved, now: .now)
            let ranked = if let trigger {
                ranker.behaviors(choices, after: trigger, pairs: pairs)
            } else {
                ranker.triggers(choices)
            }
            stepOrder = StepOrder(key: key, ids: ranked.map(\.id))
        }
        let place = stepOrder?.places ?? [:]
        return choices.enumerated()
            .sorted { (place[$0.element.id] ?? Int.max, $0.offset) < (place[$1.element.id] ?? Int.max, $1.offset) }
            .map(\.element)
    }

    /// The id of the choice that shows the step's answer: its own, or one it's now merged into.
    func answerID(in choices: [OptionChoice], for step: OptionKind) -> String? {
        guard let answer = answers[step] else { return nil }
        return choices.first { $0.id == answer.id || $0.mergedIDs.contains(answer.id) }?.id
    }

    /// The part of `choices` to show: on steps 1 and 2 the first few and More, unless the person asked for the rest
    /// or the step's answer sits past them.
    func visibleChoices(_ choices: [OptionChoice], for step: OptionKind) -> VisibleChoices {
        let cut = Self.choicesBeforeMore
        let answerIsPastCut = choices.dropFirst(cut).contains { $0.id == answerID(in: choices, for: step) }
        guard step != .result, choices.count > cut, !isShowingAllChoices, !answerIsPastCut else {
            return VisibleChoices(choices: choices, hasMore: false)
        }
        return VisibleChoices(choices: Array(choices.prefix(cut)), hasMore: true)
    }

    /// Shows the rest of the current step's choices, in the same order.
    func showAllChoices() {
        isShowingAllChoices = true
    }

    /// The option chosen for `step`, kept whole so the saved loop gets its id as well as its text.
    func answer(for step: OptionKind) -> OptionChoice? {
        answers[step]
    }

    func progress(for step: OptionKind) -> StepProgress {
        switch (answers[step] != nil, step == currentStep) {
        case (true, true): .reopened
        case (true, false): .answered
        case (false, true): .current
        case (false, false): .upcoming
        }
    }

    /// Answers the current step, then moves to the first step still unanswered, so changing an earlier answer
    /// never asks again for one already given.
    func pick(_ choice: OptionChoice) {
        guard let step = currentStep else { return }
        closeAddOwn()
        isShowingAllChoices = false
        stepOrder = nil
        answers[step] = choice
        pickCount += 1
        cheer = LogCheer(step: step, loopsLogged: loopsLogged)
        currentStep = OptionKind.allCases.first { answers[$0] == nil }
    }

    func toggleAddOwn() {
        isAddingOwn.toggle()
        draft = ""
        unsavedOption = nil
    }

    /// Saves the draft, trimmed, as the person's own option for the current step and picks it. Text that matches a
    /// choice exactly, case included, picks that choice instead of saving a duplicate; blank text does nothing.
    /// - Parameters:
    ///   - existing: The choices the step shows now.
    ///   - save: Stores a new option, given its step and its text, and returns the choice to pick. If it throws, the
    ///     text is still picked under an id of its own, since the loop keeps its own copy, and `unsavedOption` tells
    ///     the person it wasn't kept for next time.
    func addOwn(existing: [OptionChoice], save: (OptionKind, String) throws -> OptionChoice) {
        guard let step = currentStep, canAddOwn else { return }
        let label = trimmedDraft
        if let match = OptionList.match(label, in: existing) {
            pick(match)
            return
        }
        do {
            try pick(save(step, label))
        } catch {
            Self.logger.error("Couldn't save an option the person added: \(error)")
            pick(.unsavedOwn(label))
            unsavedOption = label
        }
    }

    /// Builds the loop from the answers and hands it to `store`, then sets up Nice catch. Does nothing unless
    /// `canSave`.
    /// - Parameters:
    ///   - store: Saves the loop. If it throws, `saveFailed` tells the person, and they can try again.
    ///   - loopsThisWeek: Counts this week's loops, the one just saved included. If it throws, Nice catch counts just
    ///     that one.
    func save(_ store: (Loop) throws -> Void, loopsThisWeek: () throws -> Int) {
        guard
            canSave,
            let trigger = answers[.trigger],
            let behavior = answers[.behavior],
            let result = answers[.result]
        else { return }
        let loop = Loop(trigger: trigger, behavior: behavior, result: result)
        loop.anxiety = anxiety
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        loop.note = trimmedNote.isEmpty ? nil : trimmedNote
        do {
            try store(loop)
            let count = (try? loopsThisWeek()) ?? 1
            niceCatch = NiceCatch(loop: loop, loopsThisWeek: count)
            saveFailed = false
        } catch {
            Self.logger.error("Couldn't save a loop: \(error)")
            saveFailed = true
        }
    }

    /// Opens or closes the details card. Closing it drops the level and the note, so nothing out of sight is saved.
    func toggleDetails() {
        isShowingDetails.toggle()
        if !isShowingDetails {
            anxiety = nil
            note = ""
        }
    }

    /// The levels the person can pick from.
    static let anxietyRange = 0 ... 10

    /// Sets how anxious the person felt, kept within `anxietyRange`.
    func setAnxiety(_ level: Int) {
        anxiety = min(max(level, Self.anxietyRange.lowerBound), Self.anxietyRange.upperBound)
    }

    /// Reopens a step from the summary card, keeping its answer.
    func goTo(_ step: OptionKind) {
        closeAddOwn()
        isShowingAllChoices = false
        stepOrder = nil
        // A failed save was about the loop as it stood; the person is changing it now.
        saveFailed = false
        currentStep = step
    }

    /// The field belongs to one step, so it closes, dropping the draft, when the step is answered or left. Any note
    /// about the last added option goes with it.
    private func closeAddOwn() {
        isAddingOwn = false
        draft = ""
        unsavedOption = nil
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Log")
}

/// The choices a step shows now, and whether More hides the rest.
struct VisibleChoices: Equatable {
    let choices: [OptionChoice]
    let hasMore: Bool
}

/// A step's order, kept while that step shows.
private struct StepOrder {
    /// What the order was worked out for: the step, and for step 2 the trigger.
    struct Key: Equatable {
        let step: OptionKind
        let triggerID: String?
    }

    let key: Key
    /// Each choice's place, by id.
    let places: [String: Int]

    init(key: Key, ids: [String]) {
        self.key = key
        places = Dictionary(ids.enumerated().map { ($1, $0) }) { first, _ in first }
    }
}
