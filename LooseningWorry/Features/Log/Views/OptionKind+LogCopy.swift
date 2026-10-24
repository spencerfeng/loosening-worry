import Foundation

/// What the logger says for one of a loop's steps.
struct LogStepCopy {
    /// Names the step on the summary card.
    let summaryLabel: LocalizedStringResource
    let question: LocalizedStringResource
    let hint: LocalizedStringResource
    /// Shown once the step is answered, rotated so each new loop gets the next one.
    let cheers: [LocalizedStringResource]

    /// The cheer for a loop logged after `loopsLogged` others, wrapping after the last.
    func cheer(afterLoops loopsLogged: Int) -> LocalizedStringResource {
        cheers[loopsLogged % cheers.count]
    }
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
                cheers: [
                    LocalizedStringResource("log.trigger.cheer1", defaultValue: "Spotted it. That's the first step."),
                    LocalizedStringResource(
                        "log.trigger.cheer2",
                        defaultValue: "Good catch. Naming it takes away some of its pull.",
                    ),
                    LocalizedStringResource(
                        "log.trigger.cheer3",
                        defaultValue: "There it is. Noticing is the skill you're building.",
                    ),
                ],
            )
        case .behavior:
            LogStepCopy(
                summaryLabel: LocalizedStringResource("log.behavior.summary", defaultValue: "What you did"),
                question: LocalizedStringResource("log.behavior.question", defaultValue: "What did you do?"),
                hint: LocalizedStringResource("log.behavior.hint", defaultValue: "The habit that kicked in."),
                cheers: [
                    LocalizedStringResource("log.behavior.cheer1", defaultValue: "Nice noticing. That's the habit."),
                    LocalizedStringResource(
                        "log.behavior.cheer2",
                        defaultValue: "Seen clearly, and no need to judge it.",
                    ),
                    LocalizedStringResource(
                        "log.behavior.cheer3",
                        defaultValue: "That's the pattern. Spotting it is half the work.",
                    ),
                ],
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
                cheers: [
                    LocalizedStringResource(
                        "log.result.cheer1",
                        defaultValue: "Honest answer. That's what loosens the loop.",
                    ),
                    LocalizedStringResource(
                        "log.result.cheer2",
                        defaultValue: "Thanks for checking. Your brain is taking notes.",
                    ),
                    LocalizedStringResource(
                        "log.result.cheer3",
                        defaultValue: "Seeing what it really gave you is how habits change.",
                    ),
                ],
            )
        }
    }
}

extension LogCheer {
    var message: LocalizedStringResource {
        step.logCopy.cheer(afterLoops: loopsLogged)
    }
}
