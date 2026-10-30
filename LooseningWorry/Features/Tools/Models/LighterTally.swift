import Foundation

/// How often a tool has left the person lighter, out of the runs they answered, for the finish screen's "Get curious
/// has left you lighter 5 of 7 times".
struct LighterTally: Equatable {
    let lighter: Int
    let answered: Int

    init(lighter: Int, answered: Int) {
        self.lighter = lighter
        self.answered = answered
    }

    /// None until three runs are answered, as "1 of 1 times" says nothing yet. None while fewer than half were
    /// lighter either: it's there to encourage, and a low count could read as doing it wrong.
    init?(feelings: [Feeling]) {
        let lighter = feelings.count { $0 == .lighter }
        guard feelings.count >= 3, lighter * 2 >= feelings.count else { return nil }
        self.init(lighter: lighter, answered: feelings.count)
    }

    /// "**Get curious** has left you lighter **5 of 7** times.", with the name and count in bold for the card to
    /// restyle. "times" is a plural on the number answered, written by hand in the catalog; "5 of 7" keeps together on
    /// one line.
    func sentence(naming tool: QuickTool) -> AttributedString {
        let name = String(localized: tool.name)
        return AttributedString(localized: LocalizedStringResource(
            "tool.finish.lighterTally",
            defaultValue: "**\(name)** has left you lighter **\(lighter)\u{00A0}of\u{00A0}\(answered)** times.",
        ))
    }
}
