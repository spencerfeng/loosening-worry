@testable import LooseningWorry
import Testing

/// A loop met with a tool stores the tool as its behavior and the finish screen's answer as its result.
struct QuickToolLoopTests {
    /// A loop stores these, so none may change once released.
    @Test(arguments: [
        (QuickTool.curious, "tool.curious", "Got curious"),
        (.breathe, "tool.breathe", "Breathed"),
        (.noteIt, "tool.noteIt", "Noted it"),
        (.beKind, "tool.beKind", "Was kind to myself"),
    ])
    func `each tool is a behavior with a stable id`(tool: QuickTool, id: String, label: String) {
        #expect(tool.asBehavior == OptionChoice(id: id, label: label))
    }

    @Test
    func `a loop knows the tool it was met with, and a habit has none`() {
        #expect(Loop.sample(behavior: QuickTool.breathe.asBehavior).metWithTool == .breathe)
        #expect(Loop.sample().metWithTool == nil)
        // A tool from a newer version, synced here, isn't one this version can name.
        #expect(Loop.sample(behavior: OptionChoice(id: "tool.walk", label: "Walked")).metWithTool == nil)
    }
}
