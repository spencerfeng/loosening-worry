import Foundation
@testable import LooseningWorry
import Testing

struct StarterPairsTests {
    /// New users see these behaviors first after each trigger, so every trigger needs a short list.
    @Test(arguments: StarterOption.options(for: .trigger).map(\.id))
    func `every starter trigger leads to three or four starter behaviors, each once`(trigger: StarterID) {
        let behaviors = StarterPairs.bundled.behaviors(after: trigger)

        #expect((3 ... 4).contains(behaviors.count))
        #expect(behaviors.allSatisfy { $0.kind == .behavior })
        #expect(Set(behaviors).count == behaviors.count)
    }

    @Test
    func `the map keeps each trigger's behaviors in order`() throws {
        let json = Data(#"{"trigger.news": ["behavior.scrolled", "behavior.keptChecking", "behavior.searchedOnline"]}"#
            .utf8)

        let pairs = try StarterPairs(json: json)

        #expect(pairs.behaviors(after: .news) == [.scrolled, .keptChecking, .searchedOnline])
        #expect(pairs.behaviors(after: .work).isEmpty)
    }

    /// The file is edited by hand, so a mistyped id must fail the tests, not quietly drop a pair.
    @Test(arguments: [
        #"{"trigger.newz": ["behavior.scrolled"]}"#,
        #"{"trigger.news": ["behavior.scrolld"]}"#,
    ])
    func `an id that names no starter is rejected`(json: String) {
        #expect(throws: (any Error).self) { try StarterPairs(json: Data(json.utf8)) }
    }

    /// A broken file must not stop the logger; the tests above catch it before it ships.
    @Test
    func `a file that can't be read gives an empty map`() {
        let pairs = StarterPairs.loaded(from: Data("not json".utf8))

        #expect(pairs.behaviors(after: .news).isEmpty)
    }
}
