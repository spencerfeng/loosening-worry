import Foundation
@testable import LooseningWorry
import Testing

struct PleasantnessTests {
    @Test
    func `the scale runs from very unpleasant to very pleasant in seven steps`() {
        #expect(Pleasantness.allCases.map { String(localized: $0.label) } == [
            "Very unpleasant", "Unpleasant", "Slightly unpleasant", "Neutral", "Slightly pleasant", "Pleasant",
            "Very pleasant",
        ])
    }

    /// A check-in stores these, so none may change once released.
    @Test
    func `each step has a stable id`() {
        #expect(Pleasantness.allCases.map(\.rawValue) == [
            "veryUnpleasant", "unpleasant", "slightlyUnpleasant", "neutral", "slightlyPleasant", "pleasant",
            "veryPleasant",
        ])
    }
}
