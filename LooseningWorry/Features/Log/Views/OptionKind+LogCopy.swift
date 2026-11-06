import Foundation

/// What the logger says for one of a loop's steps.
struct LogStepCopy {
    /// Names the step on the summary card.
    let summaryLabel: LocalizedStringResource
    let question: LocalizedStringResource
    let hint: LocalizedStringResource
    /// Names the "+ Add your own" field for VoiceOver.
    let addLabel: LocalizedStringResource
    /// An example in the empty "+ Add your own" field.
    let addPlaceholder: LocalizedStringResource
    /// "Edit your triggers": the step's Edit link for VoiceOver, since the visible "Edit" relies on the question.
    let editLabel: LocalizedStringResource
    /// The step's tab on the Edit options screen.
    let optionsTab: LocalizedStringResource
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
                addLabel: LocalizedStringResource("log.trigger.addLabel", defaultValue: "Add a trigger"),
                addPlaceholder: LocalizedStringResource(
                    "log.trigger.addPlaceholder",
                    defaultValue: "e.g. Call from Mom",
                ),
                editLabel: LocalizedStringResource("log.edit.triggers", defaultValue: "Edit your triggers"),
                optionsTab: LocalizedStringResource("edit.tab.triggers", defaultValue: "Triggers"),
            )
        case .behavior:
            LogStepCopy(
                summaryLabel: LocalizedStringResource("log.behavior.summary", defaultValue: "What you did"),
                question: LocalizedStringResource("log.behavior.question", defaultValue: "What did you do?"),
                hint: LocalizedStringResource("log.behavior.hint", defaultValue: "The habit that kicked in."),
                addLabel: LocalizedStringResource("log.behavior.addLabel", defaultValue: "Add a behavior"),
                addPlaceholder: LocalizedStringResource(
                    "log.behavior.addPlaceholder",
                    defaultValue: "e.g. Reread my messages",
                ),
                editLabel: LocalizedStringResource("log.edit.behaviors", defaultValue: "Edit your behaviors"),
                optionsTab: LocalizedStringResource("edit.tab.behaviors", defaultValue: "Behaviors"),
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
                addLabel: LocalizedStringResource("log.result.addLabel", defaultValue: "Add a result"),
                addPlaceholder: LocalizedStringResource("log.result.addPlaceholder", defaultValue: "e.g. Felt numb"),
                editLabel: LocalizedStringResource("log.edit.results", defaultValue: "Edit your results"),
                optionsTab: LocalizedStringResource("edit.tab.results", defaultValue: "Results"),
            )
        }
    }
}
