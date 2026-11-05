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

    /// Noticing earlier is the progress the logger's last question tracks, so Nice catch says when it happens.
    @Test(arguments: [
        (NoticeTiming.partway, NoticeTiming.afterwards),
        (.asItStarted, .afterwards),
        (.asItStarted, .partway),
    ])
    func `noticing earlier than last time for this trigger is called out`(now: NoticeTiming, last: NoticeTiming) {
        let loop = Loop.sample(noticed: now)

        let niceCatch = NiceCatch(loop: loop, loopsThisWeek: 1, lastNoticed: last)

        #expect(niceCatch.noticedEarlier)
    }

    /// Nice catch never compares against the person: a later answer, or nothing to compare, says nothing.
    @Test(arguments: [
        (.partway, .partway),
        (.afterwards, .asItStarted),
        (.asItStarted, nil),
        (nil, .afterwards),
        (nil, nil),
    ] as [(NoticeTiming?, NoticeTiming?)])
    func `otherwise nothing is said about when it was noticed`(now: NoticeTiming?, last: NoticeTiming?) {
        let loop = Loop.sample(noticed: now)

        let niceCatch = NiceCatch(loop: loop, loopsThisWeek: 1, lastNoticed: last)

        #expect(niceCatch.noticedEarlier == false)
    }

    /// Get curious until the tools exist and a rule is chosen.
    @Test
    func `the suggested tool is Get curious`() {
        let suggestion = NiceCatch(loop: Self.loop(), loopsThisWeek: 1).suggestion

        #expect(suggestion.tool == .curious)
        #expect(suggestion.detail.key == "tool.curious.detail")
    }
}
