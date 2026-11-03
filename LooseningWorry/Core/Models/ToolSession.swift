import Foundation
import SwiftData

/// In the order the tools are shown.
enum QuickTool: String, Codable, CaseIterable {
    case curious, breathe, noteIt, beKind
}

/// The answer to the finish screen's "How do you feel now?", compared to when the tool started.
enum ToolOutcome: String, Codable {
    case lighter, same, heavier
}

/// One run of a tool, with the answer from the finish screen.
@Model
final class ToolSession {
    /// The tool run, by `QuickTool` id. Kept as text so a run synced from a newer version with a tool this one doesn't
    /// know still loads. Empty only for runs saved before it existed, which belong to no tool.
    var toolID: String = ""
    var startedAt = Date.now
    var durationSeconds: Int = 0
    /// The answer to "How do you feel now?", by `ToolOutcome` id, or `nil` if the run went unanswered. Kept as text
    /// like `toolID`, so a run synced from a newer version with an answer this one doesn't know still loads.
    var outcomeID: String?
    /// Set when the tool was started from Nice catch.
    var loop: Loop?

    init(tool: QuickTool) {
        toolID = tool.rawValue
    }

    /// The tool run, or `nil` for one this version doesn't know.
    var tool: QuickTool? {
        QuickTool(rawValue: toolID)
    }

    /// The answer to "How do you feel now?", or `nil` if the run went unanswered or the answer is one this version
    /// doesn't know.
    var outcome: ToolOutcome? {
        get { outcomeID.flatMap(ToolOutcome.init(rawValue:)) }
        set { outcomeID = newValue?.rawValue }
    }

    /// A run of `tool` that started at `startedAt` and ran for `duration`, to the nearest second.
    convenience init(tool: QuickTool, startedAt: Date, duration: Duration, loop: Loop?) {
        self.init(tool: tool)
        self.startedAt = startedAt
        durationSeconds = Int((duration / .seconds(1)).rounded())
        self.loop = loop
    }
}
