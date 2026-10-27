import Foundation

/// Picks the prompts for a session of a guided tool: each session takes the next version of every stage, wrapping
/// round, so the wording changes each time and nothing repeats until every version has been used. Each tool's place
/// is kept on this device, and moves on only once a session is started.
struct PromptPicker {
    let defaults: UserDefaults
    let prompts: ToolPrompts

    /// The app's: the bundled prompts, with each tool's place kept in the standard defaults.
    static var standard: PromptPicker {
        PromptPicker(defaults: .standard, prompts: .bundled)
    }

    /// The prompts for the next session. Choosing changes nothing, so a tool can show them before it starts.
    func script(for tool: QuickTool) -> PromptScript {
        let session = defaults.integer(forKey: Key.sessionCount(of: tool))
        var start = Duration.zero
        var steps: [PromptScript.Step] = []
        for stage in prompts.stages(for: tool) where !stage.prompts.isEmpty {
            if let prompt = ToolPrompt(id: stage.prompts[session % stage.prompts.count]) {
                steps.append(PromptScript.Step(start: start, prompt: prompt))
            }
            start += stage.length
        }
        return PromptScript(steps: steps)
    }

    /// Counts a session of `tool` as used, so the next one gets the next versions.
    func countSession(of tool: QuickTool) {
        let key = Key.sessionCount(of: tool)
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    private enum Key {
        /// How many sessions of the tool have started, which picks each stage's version.
        static func sessionCount(of tool: QuickTool) -> String {
            "toolPrompts.\(tool.rawValue).sessionCount"
        }
    }
}

/// One session's prompts, each from the moment its stage begins.
struct PromptScript: Equatable {
    struct Step: Equatable {
        let start: Duration
        let prompt: ToolPrompt
    }

    let steps: [Step]

    var prompts: [ToolPrompt] {
        steps.map(\.prompt)
    }

    /// The prompt for the stage `elapsed` falls in: the last one to have begun.
    func prompt(at elapsed: Duration) -> ToolPrompt? {
        steps.last { $0.start <= elapsed }?.prompt
    }
}
