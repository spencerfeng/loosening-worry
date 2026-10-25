import Foundation
@testable import LooseningWorry
import Testing

struct NiceCatchTests {
    private static func loop(resultID: String = "result.moreWorry", result: String = "More worry") -> Loop {
        .sample(result: OptionChoice(id: resultID, label: result))
    }

    @Test
    func `shows the loop's three answers and this week's count`() {
        let niceCatch = NiceCatch(loop: Self.loop(), loopsThisWeek: 10)

        #expect(niceCatch.chips == ["Work", "Overthought it", "More worry"])
        #expect(niceCatch.loopsThisWeek == 10)
    }

    @Test(arguments: [
        (StarterID.moreWorry, "niceCatch.reflection.moreWorry"),
        (.tenseAndTired, "niceCatch.reflection.tenseAndTired"),
        (.nothingChanged, "niceCatch.reflection.nothingChanged"),
        (.littleRelief, "niceCatch.reflection.littleRelief"),
        (.actuallyHelped, "niceCatch.reflection.actuallyHelped"),
        (.notSure, "niceCatch.reflection.notSure"),
    ])
    func `each core result gets its own reflection`(result: StarterID, key: String) {
        let niceCatch = NiceCatch(loop: Self.loop(resultID: result.rawValue), loopsThisWeek: 1)

        #expect(niceCatch.reflection.key == key)
    }

    /// The reflection never quotes the person's own words, so any result without its own line gets the general one.
    @Test(arguments: ["custom.3F2A", "result.addedLater"])
    func `any other result gets the general reflection`(resultID: String) {
        let niceCatch = NiceCatch(loop: Self.loop(resultID: resultID, result: "Felt silly"), loopsThisWeek: 1)

        #expect(niceCatch.reflection.key == "niceCatch.reflection.general")
    }

    /// Get curious until the tools exist and a rule is chosen.
    @Test
    func `the suggested tool is Get curious`() {
        let suggestion = NiceCatch(loop: Self.loop(), loopsThisWeek: 1).suggestion

        #expect(suggestion.tool == .curious)
        #expect(suggestion.name.key == "tool.curious.name")
        #expect(suggestion.detail.key == "tool.curious.detail")
    }
}
