import Observation

/// Walks the person through a loop's three steps, trigger, behavior and result, one question at a time.
@Observable @MainActor
final class LogLoopViewModel {
    /// The step being asked, or `nil` once all three are answered.
    private(set) var currentStep: OptionKind? = .trigger
    private var answers: [OptionKind: String] = [:]

    func answer(for step: OptionKind) -> String? {
        answers[step]
    }

    /// Answers the current step, then moves to the first step still unanswered, so changing an earlier answer
    /// never asks again for one already given.
    func pick(_ label: String) {
        guard let step = currentStep else { return }
        answers[step] = label
        currentStep = OptionKind.allCases.first { answers[$0] == nil }
    }

    /// Reopens a step from the summary card, keeping its answer.
    func goTo(_ step: OptionKind) {
        currentStep = step
    }
}
