import Foundation
@testable import LooseningWorry
import Testing

struct ToolPromptsTests {
    @Test
    func `the bundled Get curious has three 30-second stages that fill its length`() {
        let stages = ToolPrompts.bundled.stages(for: .curious)

        #expect(stages.map(\.id) == ["find", "curious", "watch"])
        #expect(stages.allSatisfy { $0.length == .seconds(30) })
        #expect(stages.reduce(Duration.zero) { $0 + $1.length } == QuickTool.curious.length)
    }

    /// Two versions to start with; more can be added to the file and the catalog.
    @Test
    func `every Get curious stage has at least two prompts, each with its words`() {
        let stages = ToolPrompts.bundled.stages(for: .curious)

        #expect(stages.allSatisfy { $0.prompts.count >= 2 })
        #expect(stages.flatMap(\.prompts).allSatisfy { ToolPrompt(id: $0) != nil })
    }

    /// "Hmm…" is the book's cue for curiosity, so every Get curious prompt opens with it, whichever version shows.
    @Test
    func `every Get curious prompt starts with Hmm`() {
        let titles = ToolPrompts.bundled.stages(for: .curious).flatMap(\.prompts).compactMap { ToolPrompt(id: $0) }
            .map { String(localized: $0.title) }

        #expect(!titles.isEmpty)
        #expect(titles.allSatisfy { $0.hasPrefix("Hmm… ") })
    }

    /// The file is edited by hand, so a prompt with no words must fail the tests, not show a blank screen.
    @Test(arguments: [
        #"{"curious": [{"id": "find", "seconds": 30, "prompts": ["curious.find.9"]}]}"#,
        #"{"curiouz": [{"id": "find", "seconds": 30, "prompts": ["curious.find.1"]}]}"#,
    ])
    func `a prompt or tool the app doesn't know is rejected`(json: String) {
        #expect(throws: (any Error).self) { try ToolPrompts(json: Data(json.utf8)) }
    }

    /// A broken or missing file must not stop a tool; the tests above catch it before it ships.
    @Test(arguments: [Data("not json".utf8), nil])
    func `a file that can't be read gives no prompts`(data: Data?) {
        let prompts = ToolPrompts.loaded(from: data)

        #expect(prompts.stages(for: .curious).isEmpty)
    }
}
