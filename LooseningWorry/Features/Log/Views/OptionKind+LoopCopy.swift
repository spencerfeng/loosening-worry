import Foundation

/// What the logger alone says for one of a loop's steps; what it shares with the check-in is `OptionKind.copy`.
struct LoopStepCopy {
    /// Names the step on the summary card.
    let summaryLabel: LocalizedStringResource
    /// The step's tab on the Edit options screen.
    let optionsTab: LocalizedStringResource
}

extension OptionKind {
    /// The step's 1-based position in the logger.
    var stepNumber: Int {
        guard let index = Self.loopSteps.firstIndex(of: self) else {
            preconditionFailure("\(self) isn't one of a loop's steps")
        }
        return index + 1
    }

    var loopCopy: LoopStepCopy {
        switch self {
        case .trigger:
            LoopStepCopy(
                summaryLabel: LocalizedStringResource("log.trigger.summary", defaultValue: "What set you off"),
                optionsTab: LocalizedStringResource("edit.tab.triggers", defaultValue: "Triggers"),
            )
        case .behavior:
            LoopStepCopy(
                summaryLabel: LocalizedStringResource("log.behavior.summary", defaultValue: "What you did"),
                optionsTab: LocalizedStringResource("edit.tab.behaviors", defaultValue: "Behaviors"),
            )
        case .result:
            LoopStepCopy(
                summaryLabel: LocalizedStringResource("log.result.summary", defaultValue: "What it gave you"),
                optionsTab: LocalizedStringResource("edit.tab.results", defaultValue: "Results"),
            )
        case .context, .unrecognized:
            preconditionFailure("\(self) isn't one of a loop's steps")
        }
    }
}
