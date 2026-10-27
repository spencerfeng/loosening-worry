import Foundation
import SwiftData

/// In the order the tools are shown.
enum QuickTool: String, Codable, CaseIterable {
    case curious, breathe, noteIt, beKind
}

enum Feeling: String, Codable {
    case lighter, same, heavier
}

/// One run of a tool, with the answer from the finish screen.
@Model
final class ToolSession {
    var tool = QuickTool.curious
    var startedAt = Date.now
    var durationSeconds: Int = 0
    var feeling: Feeling?
    /// Set when the tool was started from Nice catch.
    var loop: Loop?

    init(tool: QuickTool) {
        self.tool = tool
    }
}
