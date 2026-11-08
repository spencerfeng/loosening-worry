import Foundation

/// What a step that offers options says: one of a loop's steps in the logger, or the check-in's contexts. The
/// logger's own words for a loop step, such as its summary label, are in `OptionKind+LoopCopy`.
struct OptionStepCopy {
    let question: LocalizedStringResource
    let hint: LocalizedStringResource
    /// Names the "+ Add your own" field for VoiceOver, and the Edit screen's add card.
    let addLabel: LocalizedStringResource
    /// An example in the empty "+ Add your own" field.
    let addPlaceholder: LocalizedStringResource
    /// "Edit your triggers": the step's Edit link for VoiceOver, since the visible "Edit" relies on the question.
    let editLabel: LocalizedStringResource
    /// The Edit screen's title.
    let editTitle: LocalizedStringResource
    /// The Edit screen's note under the list.
    let editFootnote: LocalizedStringResource
}

extension OptionKind {
    var copy: OptionStepCopy {
        switch self {
        case .trigger:
            OptionStepCopy(
                question: LocalizedStringResource("log.trigger.question", defaultValue: "What set you off?"),
                hint: LocalizedStringResource("log.trigger.hint", defaultValue: "Pick the closest one."),
                addLabel: LocalizedStringResource("log.trigger.addLabel", defaultValue: "Add a trigger"),
                addPlaceholder: LocalizedStringResource(
                    "log.trigger.addPlaceholder",
                    defaultValue: "e.g. Call from Mom",
                ),
                editLabel: LocalizedStringResource("log.edit.triggers", defaultValue: "Edit your triggers"),
                editTitle: Self.optionsTitle,
                editFootnote: Self.optionsFootnote,
            )
        case .behavior:
            OptionStepCopy(
                question: LocalizedStringResource("log.behavior.question", defaultValue: "What did you do?"),
                hint: LocalizedStringResource("log.behavior.hint", defaultValue: "The habit that kicked in."),
                addLabel: LocalizedStringResource("log.behavior.addLabel", defaultValue: "Add a behavior"),
                addPlaceholder: LocalizedStringResource(
                    "log.behavior.addPlaceholder",
                    defaultValue: "e.g. Reread my messages",
                ),
                editLabel: LocalizedStringResource("log.edit.behaviors", defaultValue: "Edit your behaviors"),
                editTitle: Self.optionsTitle,
                editFootnote: Self.optionsFootnote,
            )
        case .result:
            OptionStepCopy(
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
                editTitle: Self.optionsTitle,
                editFootnote: LocalizedStringResource(
                    "edit.footnote.results",
                    defaultValue: """
                    Core results can’t be removed and always stay in the same order, so step 3 never nudges your \
                    answer. To fix a typo in your own option, remove it and add it again.
                    """,
                ),
            )
        case .context:
            OptionStepCopy(
                question: LocalizedStringResource(
                    "checkIn.context.question",
                    defaultValue: "What's having the biggest impact on you?",
                ),
                hint: LocalizedStringResource("checkIn.context.hint", defaultValue: "Optional. Tap Done if none fits."),
                addLabel: LocalizedStringResource("checkIn.context.addLabel", defaultValue: "Add a context"),
                addPlaceholder: LocalizedStringResource(
                    "checkIn.context.addPlaceholder",
                    defaultValue: "e.g. Moving house",
                ),
                editLabel: LocalizedStringResource("checkIn.context.edit", defaultValue: "Edit your contexts"),
                editTitle: LocalizedStringResource("edit.title.contexts", defaultValue: "Your contexts"),
                editFootnote: LocalizedStringResource(
                    "edit.footnote.contexts",
                    defaultValue: """
                    Removed contexts stop showing in check-ins. Past check-ins keep them, and you can restore them \
                    any time or delete your own for good. To fix a typo, remove the context and add it again.
                    """,
                ),
            )
        case .unrecognized:
            preconditionFailure("No step offers an unrecognized kind")
        }
    }

    /// The Edit screen's title for a loop's steps, which share it as tabs.
    private static let optionsTitle = LocalizedStringResource("edit.title", defaultValue: "Your options")

    /// The Edit screen's note for triggers and behaviors.
    private static let optionsFootnote = LocalizedStringResource(
        "edit.footnote",
        defaultValue: """
        Removed options stop showing in the logger. Past loops keep them, and you can restore them any time or \
        delete your own for good. To fix a typo, remove the option and add it again.
        """,
    )
}
