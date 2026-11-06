import Foundation
@testable import LooseningWorry
import Testing

/// What Nice catch's "last times" card says. A starter habit or result gets the app's own sentences; a person's own
/// words are never lowercased or bent to fit one.
struct LastTimesTests {
    private static let start = Date(timeIntervalSince1970: 1_800_000_000)
    private static let feltSilly = OptionChoice(id: "custom.3F2A", label: "Felt silly")

    /// Loops an hour apart, oldest first, or all in the same instant.
    private static func lastTimes(
        behavior: OptionChoice = OptionChoice(.overthought, label: "Overthought it"),
        results: [OptionChoice],
        sameInstant: Bool = false,
    ) throws -> LastTimes {
        let loops = results.enumerated().map { hour, result in
            Loop.sample(
                behavior: behavior,
                result: result,
                createdAt: start.addingTimeInterval(sameInstant ? 0 : Double(hour) * 3600),
            )
        }
        return try #require(LastTimes(loops: loops))
    }

    private static func lastTimes(_ results: [StarterID]) throws -> LastTimes {
        try lastTimes(results: results.map(starter))
    }

    private static func starter(_ id: StarterID) -> OptionChoice {
        OptionChoice(id, label: String(localized: id.label))
    }

    /// The bold run is the one the card restyles.
    private static func boldRuns(in text: AttributedString) -> [String] {
        text.runs[\.inlinePresentationIntent]
            .filter { $0.0?.contains(.stronglyEmphasized) == true }
            .map { String(text[$0.1].characters) }
    }

    @Test
    func `the last times are the latest five, oldest first`() throws {
        let lastTimes = try Self.lastTimes([
            .littleRelief, .moreWorry, .tenseAndTired, .nothingChanged, .actuallyHelped, .notSure,
        ])

        #expect(lastTimes.outcomes == [.noBetter, .noBetter, .noBetter, .relief, .unclear])
        #expect(lastTimes.total == 5)
    }

    /// A result that doesn't say how it went, or one in the person's own words, isn't read as better or worse.
    @Test
    func `not sure and the person's own results are unclear`() throws {
        let lastTimes = try Self.lastTimes(results: [Self.starter(.notSure), Self.feltSilly])

        #expect(lastTimes.outcomes == [.unclear, .unclear])
    }

    @Test
    func `the top result is the one that came up most, with how often`() throws {
        let lastTimes = try Self.lastTimes([.moreWorry, .littleRelief, .moreWorry, .moreWorry])

        #expect(lastTimes.topResult == LastTimes.TopResult(result: .starter(.moreWorry), count: 3))
        #expect(lastTimes.total == 4)
    }

    @Test
    func `a tie goes to the result logged most recently`() throws {
        let lastTimes = try Self.lastTimes([.littleRelief, .moreWorry, .moreWorry, .littleRelief])

        #expect(lastTimes.topResult == LastTimes.TopResult(result: .starter(.littleRelief), count: 2))
    }

    /// Loops synced from two devices can share a time; the order they came in still decides.
    @Test
    func `a tie between loops logged in the same instant goes to the later one`() throws {
        let lastTimes = try Self.lastTimes(
            results: [Self.starter(.moreWorry), Self.starter(.littleRelief)],
            sameInstant: true,
        )

        #expect(lastTimes.topResult == LastTimes.TopResult(result: .starter(.littleRelief), count: 1))
    }

    @Test(arguments: [
        (StarterID.overthought, "The last 3 times you overthought it"),
        (.keptChecking, "The last 3 times you kept checking"),
        (.askedForReassurance, "The last 3 times you asked for reassurance"),
        (.searchedOnline, "The last 3 times you searched online"),
        (.avoidedIt, "The last 3 times you avoided it"),
        (.putItOff, "The last 3 times you put it off"),
        (.overPrepared, "The last 3 times you over-prepared"),
        (.scrolled, "The last 3 times you scrolled"),
        (.snacked, "The last 3 times you snacked"),
    ])
    func `a starter habit is part of the title`(habit: StarterID, title: String) throws {
        let lastTimes = try Self.lastTimes(behavior: Self.starter(habit), results: Array(
            repeating: Self.starter(.moreWorry),
            count: 3,
        ))

        #expect(String(localized: lastTimes.title) == title)
    }

    @Test
    func `the person's own habit follows the title as they typed it`() throws {
        let lastTimes = try Self.lastTimes(
            behavior: OptionChoice(id: "custom.1B7C", label: "I doomscrolled"),
            results: [Self.starter(.moreWorry), Self.starter(.moreWorry)],
        )

        #expect(String(localized: lastTimes.title) == "The last 2 times: I doomscrolled")
    }

    /// Options can't be renamed, so a starter's id is always the app's words, even when a loop kept older ones: from
    /// before the person changed language, or before an update reworded it.
    @Test
    func `a starter logged in older words still gets its own sentences`() throws {
        let lastTimes = try Self.lastTimes(
            behavior: OptionChoice(.overthought, label: "Overthinking"),
            results: [OptionChoice(.moreWorry, label: "Mehr Sorgen"), OptionChoice(.moreWorry, label: "More worries")],
        )

        #expect(String(localized: lastTimes.title) == "The last 2 times you overthought it")
        #expect(String(lastTimes.line.characters) == "2\u{00A0}of\u{00A0}2\u{00A0}times it gave you more worry.")
    }

    @Test(arguments: [
        (StarterID.moreWorry, "it gave you more worry."),
        (.tenseAndTired, "it left you tense and tired."),
        (.nothingChanged, "nothing changed."),
        (.littleRelief, "it gave you a little relief."),
        (.actuallyHelped, "it actually helped."),
        (.notSure, "you weren't sure what it gave you."),
    ])
    func `the line says what the most common result gave, the count in bold`(result: StarterID, ending: String) throws {
        let lastTimes = try Self.lastTimes(results: [Self.starter(result), Self.starter(result), Self.feltSilly])

        let line = lastTimes.line
        #expect(String(line.characters) == "2\u{00A0}of\u{00A0}3\u{00A0}times \(ending)")
        #expect(Self.boldRuns(in: line) == ["2\u{00A0}of\u{00A0}3\u{00A0}times"])
    }

    @Test
    func `the person's own result follows the count as they typed it`() throws {
        let own = Self.feltSilly

        let line = try Self.lastTimes(results: [own, own, Self.starter(.moreWorry)]).line

        #expect(String(line.characters) == "2\u{00A0}of\u{00A0}3\u{00A0}times: Felt silly")
        #expect(Self.boldRuns(in: line) == ["2\u{00A0}of\u{00A0}3\u{00A0}times"])
    }

    /// "times" follows the total, which is never one, so the count's own number never makes it "time".
    @Test
    func `one of two reads as times`() throws {
        let lastTimes = try Self.lastTimes(results: [Self.feltSilly, Self.starter(.moreWorry)])

        #expect(String(localized: lastTimes.title) == "The last 2 times you overthought it")
        #expect(String(lastTimes.line.characters) == "1\u{00A0}of\u{00A0}2\u{00A0}times it gave you more worry.")
    }
}
