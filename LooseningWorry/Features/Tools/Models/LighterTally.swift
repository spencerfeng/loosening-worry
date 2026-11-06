import Foundation

/// How often a tool has left the person lighter, out of every run of it, for the finish screen's "Get curious has left
/// you lighter 5 of 7 times". Like Insights' trigger page, a run left unanswered counts toward the total, never as
/// lighter.
struct LighterTally: Equatable {
    let lighter: Int
    /// Every run, answered or not.
    let total: Int

    init(lighter: Int, total: Int) {
        self.lighter = lighter
        self.total = total
    }

    /// One answer per run, `nil` for a run left unanswered. None until three runs are answered, as "1 of 1 times" says
    /// nothing yet. None while fewer than half of all runs were lighter either: it's there to encourage, and a low
    /// count could read as doing it wrong.
    init?(outcomes: [ToolOutcome?]) {
        let lighter = outcomes.count { $0 == .lighter }
        let answered = outcomes.count { $0 != nil }
        guard answered >= 3, lighter * 2 >= outcomes.count else { return nil }
        self.init(lighter: lighter, total: outcomes.count)
    }

    /// "**Get curious** has left you lighter **5 of 7** times.", with the name and count in bold for the card to
    /// restyle. "times" is a plural on the total, written by hand in the catalog; "5 of 7" keeps together on one line.
    func sentence(naming tool: QuickTool) -> AttributedString {
        let name = String(localized: tool.name)
        return AttributedString(localized: LocalizedStringResource(
            "tool.finish.lighterTally",
            defaultValue: "**\(name)** has left you lighter **\(lighter)\u{00A0}of\u{00A0}\(total)** times.",
        ))
    }
}
