import Foundation
@testable import LooseningWorry
import Testing

struct StarterOptionTests {
    @Test(arguments: [
        (OptionKind.trigger, [
            "Work email", "News", "Deadline", "Bedtime", "Social plans", "Money", "Health", "Waiting for a reply",
        ]),
        (OptionKind.behavior, [
            "Overthinking", "Checked phone", "Avoided it", "Snacked", "Over-planned", "Scrolled",
            "Asked for reassurance", "Searched online",
        ]),
        (OptionKind.result, [
            "More worry", "Tense and tired", "A little relief", "An actual answer", "Nothing changed",
            "Distracted for a while", "Restless", "Lost sleep",
        ]),
    ])
    func `each kind offers its starters in order`(kind: OptionKind, labels: [String]) {
        let starters = StarterOption.options(for: kind)

        #expect(starters.map { String(localized: $0.label) } == labels)
        #expect(starters.allSatisfy { $0.kind == kind })
    }

    /// Overrides find their starter by id, so two starters must never share one.
    @Test
    func `every starter has its own id`() {
        let ids = StarterOption.all.map(\.id)

        #expect(Set(ids).count == ids.count)
    }

    /// The catalog key is spelled out for string extraction, so it could drift from the id.
    @Test
    func `every starter's catalog key matches its id`() {
        for starter in StarterOption.all {
            #expect(starter.label.key == "starter.\(starter.id)")
        }
    }
}
