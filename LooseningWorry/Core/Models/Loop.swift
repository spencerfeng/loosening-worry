import Foundation
import SwiftData

/// One logged worry loop: what set it off, what the person did, and what that got them.
@Model
final class Loop {
    var createdAt = Date.now
    var trigger: String = ""
    var behavior: String = ""
    var result: String = ""
    /// Optional detail, 0–10.
    var anxiety: Int?
    var note: String?
    /// Tools started from this loop's Nice catch. Deleting the loop keeps the sessions.
    @Relationship(deleteRule: .nullify, inverse: \ToolSession.loop)
    var toolSessions: [ToolSession]?

    init(trigger: String, behavior: String, result: String) {
        self.trigger = trigger
        self.behavior = behavior
        self.result = result
    }
}
