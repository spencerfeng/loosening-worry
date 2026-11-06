import Foundation
@testable import LooseningWorry
import Testing

struct NiceCatchTests {
    private static let start = Date(timeIntervalSince1970: 1_800_000_000)

    /// Loops of the sample trigger and habit, an hour apart, oldest first, one per result.
    private static func loops(_ results: [StarterID]) -> [Loop] {
        results.enumerated().map { hour, result in
            .sample(
                result: OptionChoice(result, label: String(localized: result.label)),
                createdAt: start.addingTimeInterval(Double(hour) * 3600),
            )
        }
    }

    private static func niceCatch(_ results: [StarterID]) throws -> NiceCatch {
        let history = loops(results)
        return try NiceCatch(loop: #require(history.last), history: history)
    }

    @Test
    func `shows the loop's three answers`() throws {
        let niceCatch = try Self.niceCatch([.moreWorry])

        #expect(niceCatch.chips == ["Work", "Overthought it", "More worry"])
    }

    /// The urge has passed and the person may still be stirred up, so Nice catch offers something for right now.
    @Test
    func `the tool to try now is Breathe`() {
        #expect(NiceCatch.suggestion == .breathe)
    }

    /// One loop is nothing to compare with.
    @Test
    func `the last times appear once this trigger has led to this habit twice`() throws {
        #expect(try Self.niceCatch([.moreWorry]).lastTimes == nil)
        #expect(try Self.niceCatch([.moreWorry, .littleRelief]).lastTimes?.outcomes == [.noBetter, .relief])
    }
}
