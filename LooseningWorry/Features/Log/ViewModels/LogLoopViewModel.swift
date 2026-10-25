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
    /// Whether the loop has been saved, so the logger can close.
    private(set) var isSaved = false
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

    /// - Parameter loopsLogged: How many loops the person logged before this one, so each new loop gets the
    ///   next set of cheers.
    init(loopsLogged: Int = 0) {
        self.loopsLogged = loopsLogged
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
        if let match = existing.first(where: { $0.label == label }) {
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

    /// Builds the loop from the answers and hands it to `store`. Does nothing unless `canSave`.
    /// - Parameter store: Saves the loop. If it throws, `saveFailed` tells the person, and they can try again.
    func save(_ store: (Loop) throws -> Void) {
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
            isSaved = true
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
