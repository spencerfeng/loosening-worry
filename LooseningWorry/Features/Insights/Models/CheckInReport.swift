import Foundation

/// What Insights shows about check-ins for a period: how they felt, the words named most, and what weighs on the person
/// and what lifts them. Like the loops report, the period counts up to now.
struct CheckInReport {
    /// A word for a feeling, with how many check-ins in the period named it.
    struct NamedFeeling: Equatable {
        let feeling: Feeling
        let count: Int
    }

    /// A context picked on check-ins of one side: "Work, 3 of 4 check-ins".
    struct ContextShare: Equatable {
        /// What it's counted by: the choice the check-in shows, whichever copy of its words was picked.
        let id: String
        let label: String
        /// The check-ins of the side that picked it, out of every check-in of the side, those that picked no context
        /// too.
        let share: Share
    }

    /// How many check-ins felt unpleasant, neutral and pleasant.
    struct Felt: Equatable {
        let unpleasant: Int
        let neutral: Int
        let pleasant: Int

        /// Each side with its count, unpleasant to pleasant, as the bar and its rows show them.
        var bySide: [(side: Pleasantness.Side, count: Int)] {
            [(.unpleasant, unpleasant), (.neutral, neutral), (.pleasant, pleasant)]
        }
    }

    let period: InsightsPeriod
    /// The check-ins in the period up to now that this version can place on a side.
    private let checkIns: [CheckIn]
    /// Each id a context was picked under, mapped to the choice the check-in shows for it now.
    private let shownContexts: [String: OptionChoice]

    /// `saved` is the person's options, so copies of one context count as the one choice the check-in shows.
    init(checkIns: [CheckIn], saved: [LoopOption], period: InsightsPeriod, now: Date, calendar: Calendar) {
        self.period = period
        let start = period.start(now: now, calendar: calendar) ?? now
        // One holding a step this version doesn't know can't go on a side, so it's left out of the total too.
        self.checkIns = checkIns.filter { (start ... now).contains($0.createdAt) && $0.pleasantness != nil }
        shownContexts = OptionList.choicesByID(for: .context, saved: saved)
    }

    var total: Int {
        checkIns.count
    }

    var felt: Felt {
        let sides = checkIns.compactMap { $0.pleasantness?.side }
        return Felt(
            unpleasant: sides.count { $0 == .unpleasant },
            neutral: sides.count { $0 == .neutral },
            pleasant: sides.count { $0 == .pleasant },
        )
    }

    /// The five words named most, most first; words named as often go alphabetically, as the check-in lists them.
    var namedFeelings: [NamedFeeling] {
        var counts: [Feeling: Int] = [:]
        for feeling in checkIns.flatMap(\.feelings) {
            counts[feeling, default: 0] += 1
        }
        let named = counts.map { NamedFeeling(feeling: $0.key, count: $0.value) }
        return Self.top(5, of: named, count: \.count) { String(localized: $0.feeling.label) }
    }

    /// "What weighs on you": the three contexts picked most on unpleasant check-ins.
    var weighs: [ContextShare] {
        contexts(on: .unpleasant)
    }

    /// "What lifts you": the three contexts picked most on pleasant check-ins.
    var lifts: [ContextShare] {
        contexts(on: .pleasant)
    }

    /// The three contexts picked most on check-ins of `side`, most first; ones picked as often go alphabetically.
    private func contexts(on side: Pleasantness.Side) -> [ContextShare] {
        let onSide = checkIns.filter { $0.pleasantness?.side == side }
        var counts: [String: (label: String, count: Int)] = [:]
        for checkIn in onSide {
            // One no longer shown, such as one removed, keeps its own id and its text as picked. Each context counts
            // once per check-in, which can hold two copies of it picked before sync merged them.
            var seen: Set<String> = []
            for context in checkIn.contexts.map({ shownContexts[$0.id] ?? $0 }) where seen.insert(context.id).inserted {
                counts[context.id, default: (context.label, 0)].count += 1
            }
        }
        let shares = counts.map { id, picked in
            ContextShare(id: id, label: picked.label, share: Share(count: picked.count, total: onSide.count))
        }
        return Self.top(3, of: shares, count: \.share.count, label: \.label)
    }

    /// The `limit` items counted most, most first; ones counted as often go alphabetically by `label`, as the check-in
    /// lists words and contexts.
    private static func top<Item>(
        _ limit: Int,
        of items: [Item],
        count: (Item) -> Int,
        label: (Item) -> String,
    ) -> [Item] {
        let ranked = items.sorted { lhs, rhs in
            if count(lhs) != count(rhs) {
                return count(lhs) > count(rhs)
            }
            return label(lhs).localizedStandardCompare(label(rhs)) == .orderedAscending
        }
        return Array(ranked.prefix(limit))
    }

    /// Five check-ins before the cards show, so they don't draw a pattern from one or two.
    var hasEnough: Bool {
        total >= 5
    }
}
