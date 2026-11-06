import Foundation

/// "The last 5 times you overthought it": what the habit gave the person each of the last times this trigger set it
/// off, so they see it plainly.
struct LastTimes: Equatable {
    /// The result that came up most, and how often.
    struct TopResult: Equatable {
        let result: Wording
        let count: Int
    }

    /// How many of the latest loops it looks at.
    static let limit = 5

    /// The habit, as last logged.
    let habit: Wording
    /// What each result gave, for its dot: at most `limit`, oldest first.
    let outcomes: [ResultOutcome]
    /// A tie goes to the result logged most recently.
    let topResult: TopResult

    var total: Int {
        outcomes.count
    }

    /// `loops` is oldest first; only the last `limit` count. `nil` with fewer than two.
    init?(loops: [Loop]) {
        let last = Array(loops.suffix(Self.limit))
        guard last.count >= 2, let latest = last.last else { return nil }
        habit = Wording(id: latest.behaviorID, label: latest.behaviorLabel)
        outcomes = last.map { ResultOutcome(resultID: $0.resultID) }
        // Each result's count and where it was last logged; the order, not the time, breaks a tie, so two loops logged
        // in the same instant still give one answer.
        var tallies: [String: (count: Int, lastIndex: Int)] = [:]
        for (index, loop) in last.enumerated() {
            tallies[loop.resultID, default: (0, index)].count += 1
            tallies[loop.resultID]?.lastIndex = index
        }
        guard let top = tallies.values.max(by: { ($0.count, $0.lastIndex) < ($1.count, $1.lastIndex) }) else {
            return nil
        }
        let loop = last[top.lastIndex]
        topResult = TopResult(result: Wording(id: loop.resultID, label: loop.resultLabel), count: top.count)
    }
}
