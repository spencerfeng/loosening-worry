import Foundation

/// What the logger says for one of a loop's steps.
struct LogStepCopy {
    /// Names the step on the summary card.
    let summaryLabel: LocalizedStringResource
    let question: LocalizedStringResource
    let hint: LocalizedStringResource
}

extension OptionKind {
    /// The step's 1-based position in the logger.
    var stepNumber: Int {
        (Self.allCases.firstIndex(of: self) ?? 0) + 1
    }

    var logCopy: LogStepCopy {
        switch self {
        case .trigger:
            LogStepCopy(
                summaryLabel: LocalizedStringResource("log.trigger.summary", defaultValue: "What set you off"),
                question: LocalizedStringResource("log.trigger.question", defaultValue: "What set you off?"),
                hint: LocalizedStringResource("log.trigger.hint", defaultValue: "Pick the closest one."),
            )
        case .behavior:
            LogStepCopy(
                summaryLabel: LocalizedStringResource("log.behavior.summary", defaultValue: "What you did"),
                question: LocalizedStringResource("log.behavior.question", defaultValue: "What did you do?"),
                hint: LocalizedStringResource("log.behavior.hint", defaultValue: "The habit that kicked in."),
            )
        case .result:
            LogStepCopy(
                summaryLabel: LocalizedStringResource("log.result.summary", defaultValue: "What it gave you"),
                question: LocalizedStringResource(
                    "log.result.question",
                    defaultValue: "What did it actually give you?",
                ),
                hint: LocalizedStringResource(
                    "log.result.hint",
                    defaultValue: "Take one breath and notice how it really feels.",
                ),
            )
        }
    }
}
