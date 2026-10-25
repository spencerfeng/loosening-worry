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
    /// Tools started from this loop's Nice catch. Deleting the loop keeps the sessions.
    @Relationship(deleteRule: .nullify, inverse: \ToolSession.loop)
    var toolSessions: [ToolSession]?

    init(trigger: OptionChoice, behavior: OptionChoice, result: OptionChoice) {
        triggerID = trigger.id
        triggerLabel = trigger.label
        behaviorID = behavior.id
        behaviorLabel = behavior.label
        resultID = result.id
        resultLabel = result.label
    }
}
