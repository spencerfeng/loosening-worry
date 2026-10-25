import Foundation
@testable import LooseningWorry

extension Loop {
    /// A loop with starter answers, logged at `createdAt`.
    static func sample(
        trigger: OptionChoice = OptionChoice(.work, label: "Work"),
        behavior: OptionChoice = OptionChoice(.overthought, label: "Overthought it"),
        result: OptionChoice = OptionChoice(.moreWorry, label: "More worry"),
        createdAt: Date = .now,
    ) -> Loop {
        let loop = Loop(trigger: trigger, behavior: behavior, result: result)
        loop.createdAt = createdAt
        return loop
    }
}
