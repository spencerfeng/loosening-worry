import Foundation
import Observation
import os

/// Walks the person through a loop's three steps, trigger, behavior and result, one question at a time.
@Observable @MainActor
final class LogLoopViewModel {
    /// The step being asked, or `nil` once all three are answered.
    private(set) var currentStep: OptionKind? = .trigger
    private var answers: [OptionKind: String] = [:]
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

    func answer(for step: OptionKind) -> String? {
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
    func pick(_ label: String) {
        guard let step = currentStep else { return }
        closeAddOwn()
        answers[step] = label
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
    ///   - save: Stores a new option: its step, and its text. If it throws, the text is still picked, since the
    ///     loop keeps its own copy, and `unsavedOption` tells the person it wasn't kept for next time.
    func addOwn(existing: [OptionChoice], save: (OptionKind, String) throws -> Void) {
        guard let step = currentStep, canAddOwn else { return }
        let label = trimmedDraft
        var saveFailed = false
        if !existing.contains(where: { $0.label == label }) {
            do {
                try save(step, label)
            } catch {
                Self.logger.error("Couldn't save an option the person added: \(error)")
                saveFailed = true
            }
        }
        pick(label)
        if saveFailed {
            unsavedOption = label
        }
    }

    /// Reopens a step from the summary card, keeping its answer.
    func goTo(_ step: OptionKind) {
        closeAddOwn()
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
