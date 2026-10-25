import Foundation

/// What Nice catch shows once a loop is saved: the loop, a line reflecting on what it gave the person, how many loops
/// they've noticed this week, and a tool to try.
struct NiceCatch {
    /// Trigger, behavior and result, as logged.
    let chips: [String]
    let reflection: LocalizedStringResource
    /// Includes the loop just saved.
    let loopsThisWeek: Int
    let suggestion: ToolSuggestion

    init(loop: Loop, loopsThisWeek: Int) {
        chips = [loop.triggerLabel, loop.behaviorLabel, loop.resultLabel]
        reflection = Self.reflection(forResult: loop.resultID)
        self.loopsThisWeek = loopsThisWeek
        suggestion = Self.suggestion(for: loop)
    }

    /// A tool to try, with the words that offer it.
    struct ToolSuggestion {
        let tool: QuickTool
        let name: LocalizedStringResource
        let detail: LocalizedStringResource
    }

    /// Get curious for every loop until the tools exist and a rule for choosing one is agreed. The rule goes here,
    /// with each tool's words, so a tool is never offered with another's.
    private static func suggestion(for _: Loop) -> ToolSuggestion {
        ToolSuggestion(
            tool: .curious,
            name: LocalizedStringResource("tool.curious.name", defaultValue: "Get curious"),
            detail: LocalizedStringResource("tool.curious.detail", defaultValue: "90 sec · explore the feeling"),
        )
    }

    /// One line per core result. It never quotes the person's words, so their own results, and any this version
    /// doesn't know, get the general line. The wording is a draft for the psychologist reviewer.
    private static func reflection(forResult id: String) -> LocalizedStringResource {
        switch StarterID(rawValue: id) {
        case .moreWorry:
            LocalizedStringResource(
                "niceCatch.reflection.moreWorry",
                defaultValue: "It gave you more worry. Noticing that is how the habit starts to loosen.",
            )
        case .tenseAndTired:
            LocalizedStringResource(
                "niceCatch.reflection.tenseAndTired",
                defaultValue: "It left you tense and tired. Noticing that is how the habit starts to loosen.",
            )
        case .nothingChanged:
            LocalizedStringResource(
                "niceCatch.reflection.nothingChanged",
                defaultValue: "It didn't change anything. Noticing that is how the habit starts to loosen.",
            )
        case .littleRelief:
            LocalizedStringResource(
                "niceCatch.reflection.littleRelief",
                defaultValue: "A little relief, for now. Noticing what it really gives you is how the habit loosens.",
            )
        case .actuallyHelped:
            LocalizedStringResource(
                "niceCatch.reflection.actuallyHelped",
                defaultValue: "It helped this time. Noticing honestly is what matters.",
            )
        case .notSure:
            LocalizedStringResource(
                "niceCatch.reflection.notSure",
                defaultValue: "Not sure is an honest answer. Noticing is how the habit starts to loosen.",
            )
        default:
            LocalizedStringResource(
                "niceCatch.reflection.general",
                defaultValue: "Noticing what it gave you is how the habit starts to loosen.",
            )
        }
    }
}
