import Foundation
@testable import LooseningWorry
import Testing

@MainActor
final class PromptPickerTests {
    /// Each test gets its own defaults, so nothing leaks between tests or into the app.
    private let suiteName = "PromptPickerTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    /// The same stages for two tools, the second stage with three versions.
    private let prompts: ToolPrompts

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        let stages = """
        [
          { "id": "find", "seconds": 30, "prompts": ["curious.find.1", "curious.find.2"] },
          { "id": "curious", "seconds": 30, "prompts": ["curious.curious.1", "curious.curious.2", "curious.watch.1"] }
        ]
        """
        prompts = try ToolPrompts(json: Data(#"{"curious": \#(stages), "breathe": \#(stages)}"#.utf8))
    }

    isolated deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private var picker: PromptPicker {
        PromptPicker(defaults: defaults, prompts: prompts)
    }

    /// A session's prompts, then counting it as started.
    private func nextSession(_ tool: QuickTool = .curious) -> [String] {
        let ids = picker.script(for: tool).prompts.map(\.id)
        picker.countSession(of: tool)
        return ids
    }

    @Test
    func `each session takes the next version of every stage, wrapping round, and remembers its place`() {
        #expect(nextSession() == ["curious.find.1", "curious.curious.1"])
        #expect(nextSession() == ["curious.find.2", "curious.curious.2"])
        #expect(nextSession() == ["curious.find.1", "curious.watch.1"])
        #expect(nextSession() == ["curious.find.2", "curious.curious.1"])
    }

    /// Choosing the prompts changes nothing until the session is counted, so a tool can show them before Play.
    @Test
    func `the same prompts come back until a session is counted`() {
        #expect(picker.script(for: .curious) == picker.script(for: .curious))
    }

    @Test
    func `each tool keeps its own place`() {
        _ = nextSession()

        #expect(nextSession(.breathe) == ["curious.find.1", "curious.curious.1"])
    }

    @Test(arguments: [
        (0.0, "curious.find.1"),
        (29.9, "curious.find.1"),
        (30.0, "curious.curious.1"),
        (90.0, "curious.curious.1")
    ])
    func `the prompt shown is the one whose stage the time is in`(seconds: Double, expected: String) {
        let script = picker.script(for: .curious)

        #expect(script.prompt(at: .seconds(seconds))?.id == expected)
    }

    @Test
    func `with no stages there's no prompt to show`() {
        let script = picker.script(for: .noteIt)

        #expect(script.prompt(at: .zero) == nil)
    }
}
