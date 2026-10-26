import Foundation
@testable import LooseningWorry
import Testing

struct LoopOptionTests {
    @Test
    func `an option with no starter is the person's own`() {
        #expect(LoopOption(kind: .trigger, label: "Rent due").isCustom)
        #expect(LoopOption(overriding: .news, label: "News").isCustom == false)
    }

    /// Two devices can each change the same starter before they sync; every device must pick the same winner.
    @Test
    func `the change edited last wins, and on a tie the one created last`() {
        let older = LoopOption(overriding: .news, label: "News")
        older.createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        older.updatedAt = Date(timeIntervalSince1970: 1_700_200_000)
        let newer = LoopOption(overriding: .news, label: "News")
        newer.createdAt = Date(timeIntervalSince1970: 1_700_100_000)
        newer.updatedAt = Date(timeIntervalSince1970: 1_700_100_000)

        #expect(older.supersedes(newer))
        #expect(!newer.supersedes(older))

        newer.updatedAt = older.updatedAt

        #expect(newer.supersedes(older))
        #expect(!older.supersedes(newer))
    }
}
