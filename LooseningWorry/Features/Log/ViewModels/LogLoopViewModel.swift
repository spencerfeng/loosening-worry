import Observation

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
        answers[step] = label
        pickCount += 1
        cheer = LogCheer(step: step, loopsLogged: loopsLogged)
        currentStep = OptionKind.allCases.first { answers[$0] == nil }
    }

    /// Reopens a step from the summary card, keeping its answer.
    func goTo(_ step: OptionKind) {
        currentStep = step
    }
}
