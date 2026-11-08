import Foundation
import SwiftData

/// One logged worry loop: what set it off, what the person did, and what that got them.
@Model
final class Loop {
    var createdAt = Date.now
    /// What history counts the trigger by, as `OptionChoice.id` gives it. Unlike the text, it survives the option
    /// being removed and restored, or a starter showing in another language.
    var triggerID: String = ""
    /// What history counts the behavior by, like `triggerID`.
    var behaviorID: String = ""
    /// What history counts the result by, like `triggerID`.
    var resultID: String = ""
    /// The trigger's text as shown when logged, so history and export still read right after the option is removed.
    var triggerLabel: String = ""
    /// The behavior's text as shown when logged, like `triggerLabel`.
    var behaviorLabel: String = ""
    /// The result's text as shown when logged, like `triggerLabel`.
    var resultLabel: String = ""
    /// Optional detail, 0–10.
    var anxiety: Int?
    var note: String?
    /// When the person noticed it, by `NoticeTiming` id; `nil` if they didn't say. Kept as text so a loop synced from
    /// a newer version with an answer this one doesn't know still loads.
    var noticedID: String?
    /// Tools started from this loop's Nice catch. Deleting the loop keeps the sessions.
    @Relationship(deleteRule: .nullify, inverse: \ToolSession.loop)
    var toolSessions: [ToolSession]?

    init(trigger: OptionChoice, behavior: OptionChoice, result: OptionChoice) {
        triggerID = trigger.id
        triggerLabel = trigger.label
        behaviorID = behavior.id
        behaviorLabel = behavior.label
        setResult(result)
    }

    /// Replaces what the loop gave the person, such as when a tool's finish screen is answered after it was saved.
    func setResult(_ result: OptionChoice) {
        resultID = result.id
        resultLabel = result.label
    }

    /// The answer to one of the loop's steps, with the id it's counted by and its text as logged; `nil` for a kind that
    /// isn't a loop step.
    func answer(for step: OptionKind) -> OptionChoice? {
        switch step {
        case .trigger: OptionChoice(id: triggerID, label: triggerLabel)
        case .behavior: OptionChoice(id: behaviorID, label: behaviorLabel)
        case .result: OptionChoice(id: resultID, label: resultLabel)
        case .context, .unrecognized: nil
        }
    }

    /// When the person noticed it, or `nil` if they didn't say or the answer is one this version doesn't know.
    var noticed: NoticeTiming? {
        get { noticedID.flatMap(NoticeTiming.init(rawValue:)) }
        set { noticedID = newValue?.rawValue }
    }
}
