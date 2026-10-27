import Foundation
import os

/// The stages a guided tool goes through, each with a pool of prompts to rotate through, from `tool-prompts.json`.
/// The file holds only the structure and prompt ids, so a reviewer can rearrange it without touching code; each
/// prompt's words live in the string catalog (see `ToolPrompt`).
struct ToolPrompts: Sendable {
    /// One stretch of a tool, such as Get curious's "find it".
    struct Stage: Decodable, Equatable, Sendable {
        let id: String
        let seconds: Int
        /// The ids of the prompt's versions, in the order sessions rotate through them.
        let prompts: [String]

        var length: Duration {
            .seconds(seconds)
        }
    }

    private let stagesByTool: [QuickTool: [Stage]]

    /// - Throws: If the JSON is malformed, a key names no tool, or a prompt id has no words.
    init(json: Data) throws {
        let raw = try JSONDecoder().decode([String: [Stage]].self, from: json)
        var stagesByTool: [QuickTool: [Stage]] = [:]
        for (key, stages) in raw {
            guard let tool = QuickTool(rawValue: key) else { throw Unknown(id: key) }
            for id in stages.flatMap(\.prompts) where ToolPrompt(id: id) == nil {
                throw Unknown(id: id)
            }
            stagesByTool[tool] = stages
        }
        self.stagesByTool = stagesByTool
    }

    /// In order; none for a tool the file doesn't guide.
    func stages(for tool: QuickTool) -> [Stage] {
        stagesByTool[tool] ?? []
    }

    /// The prompts shipped with the app. Tests check every stage and prompt.
    static let bundled: ToolPrompts = {
        guard let url = Bundle.main.url(forResource: "tool-prompts", withExtension: "json") else {
            return loaded(from: nil)
        }
        do {
            return try loaded(from: Data(contentsOf: url))
        } catch {
            logger.error("Couldn't read tool-prompts.json: \(error)")
            return .empty
        }
    }()

    /// No prompts: a guided tool then shows its fallback.
    static let empty = ToolPrompts(stagesByTool: [:])

    /// The prompts in `data`, or none if there's no file or it can't be read.
    static func loaded(from data: Data?) -> ToolPrompts {
        guard let data else {
            logger.error("tool-prompts.json is missing from the app")
            return .empty
        }
        do {
            return try ToolPrompts(json: data)
        } catch {
            logger.error("Couldn't decode tool-prompts.json: \(error)")
            return .empty
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Tools")

    private init(stagesByTool: [QuickTool: [Stage]]) {
        self.stagesByTool = stagesByTool
    }

    private struct Unknown: Error {
        let id: String
    }
}

/// A prompt's words: a short line to hold in mind and a sentence to guide it. Each id in `tool-prompts.json` needs a
/// case here, written out so the words reach the string catalog. All are drafts for the psychologist reviewer.
struct ToolPrompt: Equatable {
    let id: String
    let title: LocalizedStringResource
    let detail: LocalizedStringResource

    /// `nil` for an id with no words, which the tests catch before it ships.
    init?(id: String) {
        guard let words = Self.words(for: id) else { return nil }
        self.id = id
        (title, detail) = words
    }

    static func == (lhs: ToolPrompt, rhs: ToolPrompt) -> Bool {
        lhs.id == rhs.id
    }

    private static func words(for id: String) -> (LocalizedStringResource, LocalizedStringResource)? {
        switch id {
        case "curious.find.1":
            (
                LocalizedStringResource("tool.prompt.curious.find.1.title", defaultValue: "Hmm… where is it?"),
                LocalizedStringResource(
                    "tool.prompt.curious.find.1.detail",
                    defaultValue: "Scan from your head to your feet. Where do you feel the worry most?",
                ),
            )
        case "curious.find.2":
            (
                LocalizedStringResource("tool.prompt.curious.find.2.title", defaultValue: "Hmm… where do you feel it?"),
                LocalizedStringResource(
                    "tool.prompt.curious.find.2.detail",
                    defaultValue: "Chest, stomach, throat, shoulders? Notice where it sits, just as it is.",
                ),
            )
        case "curious.curious.1":
            (
                LocalizedStringResource(
                    "tool.prompt.curious.curious.1.title",
                    defaultValue: "Hmm… what is this feeling?",
                ),
                LocalizedStringResource(
                    "tool.prompt.curious.curious.1.detail",
                    defaultValue: "Is it tight or loose? Warm or cool? Moving or still? Just notice, like a scientist.",
                ),
            )
        case "curious.curious.2":
            (
                LocalizedStringResource("tool.prompt.curious.curious.2.title", defaultValue: "Hmm… what's it like?"),
                LocalizedStringResource(
                    "tool.prompt.curious.curious.2.detail",
                    defaultValue: "Heavy or light? Sharp or dull? Big or small? There's no right answer.",
                ),
            )
        case "curious.watch.1":
            (
                LocalizedStringResource("tool.prompt.curious.watch.1.title", defaultValue: "Hmm… is it changing?"),
                LocalizedStringResource(
                    "tool.prompt.curious.watch.1.detail",
                    defaultValue: "Stronger, weaker, moving? Watch it, and let it do whatever it does.",
                ),
            )
        case "curious.watch.2":
            (
                LocalizedStringResource(
                    "tool.prompt.curious.watch.2.title",
                    defaultValue: "Hmm… what happens if you stay with it?",
                ),
                LocalizedStringResource(
                    "tool.prompt.curious.watch.2.detail",
                    defaultValue: "Keep looking with curiosity. Notice how it feels to watch it, rather than worry.",
                ),
            )
        default:
            nil
        }
    }
}
