import Foundation
@testable import LooseningWorry
import Testing

struct LighterTallyTests {
    /// The bold runs are the ones the card restyles; grouped by emphasis alone, as each number is a run of its own.
    private func boldRuns(in text: AttributedString) -> [String] {
        text.runs[\.inlinePresentationIntent]
            .filter { $0.0?.contains(.stronglyEmphasized) == true }
            .map { String(text[$0.1].characters) }
    }

    @Test
    func `the sentence names the tool and the count, both in bold`() {
        let text = LighterTally(lighter: 5, answered: 7).sentence(naming: .curious)

        #expect(String(text.characters) == "Get curious has left you lighter 5\u{00A0}of\u{00A0}7 times.")
        #expect(boldRuns(in: text) == ["Get curious", "5\u{00A0}of\u{00A0}7"])
    }

    /// The source's own wording always says "times"; "time" comes only from the catalog's plural.
    @Test
    func `one answered run reads as one time`() {
        let text = LighterTally(lighter: 1, answered: 1).sentence(naming: .breathe)

        #expect(String(text.characters) == "Breathe has left you lighter 1\u{00A0}of\u{00A0}1 time.")
        #expect(boldRuns(in: text) == ["Breathe", "1\u{00A0}of\u{00A0}1"])
    }
}
