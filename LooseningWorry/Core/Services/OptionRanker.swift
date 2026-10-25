import Foundation

/// Orders a step's choices by the person's history, so the options they're likely to pick come first. It only ever
/// reorders: every choice it's given comes back.
///
/// Only loops from the last 90 days count, including any dated later than now by a device whose clock runs fast. A
/// choice counts the loops logged under any of its ids, its own and its
/// `mergedIDs`, so copies of one text count as one option. Step 3 is never ranked.
struct OptionRanker {
    let loops: [Loop]
    /// The person's options, for when each of their own was added.
    let saved: [LoopOption]
    let now: Date

    /// Step 1: the person's own triggers added in the last 7 days, then by how often each was logged, then their own
    /// before starters, then the order given.
    func triggers(_ choices: [OptionChoice]) -> [OptionChoice] {
        let recent = recentLoops
        return ranked(choices) { choice in
            [uses(of: choice, in: recent, at: \.triggerID)]
        }
    }

    /// Step 2, after `trigger`: the person's own behaviors added in the last 7 days come first. Once the trigger has
    /// three loops, the rest go by how often each was logged with it, then by how often at all. Before that, the
    /// trigger's starter map leads, then overall use. Ties go to the person's own, then the order given.
    func behaviors(_ choices: [OptionChoice], after trigger: OptionChoice, pairs: StarterPairs) -> [OptionChoice] {
        let recent = recentLoops
        let triggerIDs = Self.ids(of: trigger)
        let withTrigger = recent.filter { triggerIDs.contains($0.triggerID) }
        if withTrigger.count >= Self.loopsToTrustPairings {
            return ranked(choices) { choice in
                [uses(of: choice, in: withTrigger, at: \.behaviorID), uses(of: choice, in: recent, at: \.behaviorID)]
            }
        }
        // The person's own trigger has no map, unless one of its ids is a starter's.
        let starter = triggerIDs.lazy.compactMap(StarterID.init(rawValue:)).first
        let mapped = starter.map(pairs.behaviors(after:)) ?? []
        return ranked(choices) { choice in
            let ids = Self.ids(of: choice)
            // Earlier in the map ranks higher; behaviors it doesn't list tie at zero.
            let mapRank = mapped.firstIndex { ids.contains($0.rawValue) }.map { mapped.count - $0 } ?? 0
            return [mapRank, uses(of: choice, in: recent, at: \.behaviorID)]
        }
    }

    /// The earliest a loop can be and still count, so callers can read only that much history.
    static func historyStart(before now: Date) -> Date {
        days(historyDays, before: now)
    }

    // MARK: - Shared rules

    /// Below this many loops with a trigger, its pairings are too few to go by, so the starter map leads.
    private static let loopsToTrustPairings = 3

    private static let historyDays: Double = 90
    private static let newOwnDays: Double = 7

    private var recentLoops: [Loop] {
        let start = Self.historyStart(before: now)
        return loops.filter { $0.createdAt >= start }
    }

    private static func days(_ days: Double, before date: Date) -> Date {
        date.addingTimeInterval(-days * 24 * 60 * 60)
    }

    private static func ids(of choice: OptionChoice) -> Set<String> {
        Set([choice.id] + choice.mergedIDs)
    }

    private func uses(of choice: OptionChoice, in loops: [Loop], at answer: KeyPath<Loop, String>) -> Int {
        let ids = Self.ids(of: choice)
        return loops.count { ids.contains($0[keyPath: answer]) }
    }

    /// Whether `choice` is the person's own, added in the last 7 days.
    private func isNewOwn(_ choice: OptionChoice) -> Bool {
        guard choice.starterID == nil else { return false }
        let start = Self.days(Self.newOwnDays, before: now)
        return saved.contains { $0.optionID == choice.id && $0.createdAt > start }
    }

    /// New own options first, in the order given. The rest by `counts`, highest first and compared in turn, then
    /// the person's own before starters, then the order given.
    private func ranked(_ choices: [OptionChoice], by counts: (OptionChoice) -> [Int]) -> [OptionChoice] {
        let newOwn = choices.filter(isNewOwn)
        let rest = choices.enumerated()
            .filter { !isNewOwn($0.element) }
            .map { (place: $0.offset, choice: $0.element, counts: counts($0.element)) }
            .sorted { lhs, rhs in
                if lhs.counts != rhs.counts {
                    return lhs.counts.lexicographicallyPrecedes(rhs.counts, by: >)
                }
                let lhsOwn = lhs.choice.starterID == nil
                let rhsOwn = rhs.choice.starterID == nil
                if lhsOwn != rhsOwn {
                    return lhsOwn
                }
                return lhs.place < rhs.place
            }
            .map(\.choice)
        return newOwn + rest
    }
}
