import Foundation
@testable import LooseningWorry
import Testing

/// Step 1: triggers ordered by how often the person logged them.
struct OptionRankerTriggerTests {
    let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func daysAgo(_ days: Double) -> Date {
        now.addingTimeInterval(-days * 24 * 60 * 60)
    }

    private func loop(_ trigger: StarterID, daysAgo days: Double = 1) -> Loop {
        .sample(trigger: OptionChoice(trigger, label: ""), createdAt: daysAgo(days))
    }

    private func starters() -> [OptionChoice] {
        OptionList.choices(for: .trigger, saved: [])
    }

    @Test
    func `with no history, the order is left as it is`() {
        let ranker = OptionRanker(loops: [], saved: [], now: now)

        #expect(ranker.triggers(starters()) == starters())
    }

    @Test
    func `triggers logged more often come first, the rest keep their order`() {
        let loops = [loop(.money), loop(.news), loop(.news)]
        let ranker = OptionRanker(loops: loops, saved: [], now: now)

        let ranked = ranker.triggers(starters()).compactMap(\.starterID)

        #expect(Array(ranked.prefix(2)) == [.news, .money])
        #expect(Array(ranked.dropFirst(2)) == starters().compactMap(\.starterID)
            .filter { ![.news, .money].contains($0) })
    }

    @Test
    func `only the last 90 days count`() {
        let loops = [loop(.money, daysAgo: 91), loop(.money, daysAgo: 95), loop(.news, daysAgo: 89)]
        let ranker = OptionRanker(loops: loops, saved: [], now: now)

        #expect(ranker.triggers(starters()).first?.starterID == .news)
    }

    /// A newly added option is easy to pick again, even before it has any history.
    @Test
    func `the person's own option added in the last 7 days comes first`() {
        let rent = LoopOption(kind: .trigger, label: "Rent due")
        rent.createdAt = daysAgo(2)
        let older = LoopOption(kind: .trigger, label: "Call from Mom")
        older.createdAt = daysAgo(30)
        let saved = [rent, older]
        let ranker = OptionRanker(loops: [loop(.news), loop(.news)], saved: saved, now: now)

        let ranked = ranker.triggers(OptionList.choices(for: .trigger, saved: saved))

        #expect(ranked.map(\.label).prefix(2) == ["Rent due", "News"])
    }

    @Test
    func `on a tie, the person's own come before starters`() {
        let rent = LoopOption(kind: .trigger, label: "Rent due")
        rent.createdAt = daysAgo(30)
        let loops = [loop(.money), .sample(trigger: OptionChoice(rent), createdAt: daysAgo(1))]
        let ranker = OptionRanker(loops: loops, saved: [rent], now: now)

        let ranked = ranker.triggers(OptionList.choices(for: .trigger, saved: [rent]))

        #expect(ranked.map(\.label).prefix(2) == ["Rent due", "Money"])
    }

    /// Two ids showing one text, such as a starter and the person's own option with its words, are one option to
    /// the person, so loops under either count for it.
    @Test
    func `loops logged under any id a choice shows count for it`() {
        let copy = LoopOption(kind: .trigger, label: "News")
        copy.createdAt = daysAgo(30)
        let loops = [
            loop(.money), loop(.money),
            loop(.news), .sample(trigger: OptionChoice(copy), createdAt: daysAgo(1)), loop(.news),
        ]
        let ranker = OptionRanker(loops: loops, saved: [copy], now: now)

        // Their own "News" shows, with the starter's id merged into it: three loops to Money's two.
        let ranked = ranker.triggers(OptionList.choices(for: .trigger, saved: [copy]))

        #expect(ranked.map(\.label).prefix(2) == ["News", "Money"])
    }

    @Test(arguments: [(6.9, true), (7.1, false)])
    func `the boost for a new option of the person's own lasts 7 days`(age: Double, leads: Bool) {
        let rent = LoopOption(kind: .trigger, label: "Rent due")
        rent.createdAt = daysAgo(age)
        let ranker = OptionRanker(loops: [loop(.news)], saved: [rent], now: now)

        let ranked = ranker.triggers(OptionList.choices(for: .trigger, saved: [rent]))

        #expect((ranked.first?.label == "Rent due") == leads)
    }

    @Test
    func `a loop from exactly 90 days ago still counts`() {
        let ranker = OptionRanker(loops: [loop(.money, daysAgo: 90)], saved: [], now: now)

        #expect(ranker.triggers(starters()).first?.starterID == .money)
    }

    /// A device whose clock runs fast can sync a loop dated after now; it's still a loop the person logged.
    @Test
    func `a loop dated later than now counts`() {
        let ranker = OptionRanker(loops: [loop(.money, daysAgo: -1)], saved: [], now: now)

        #expect(ranker.triggers(starters()).first?.starterID == .money)
    }

    /// Counting is by id, and bringing an option back keeps its id, so its history comes back with it.
    @Test
    func `an option removed and brought back keeps its count`() {
        let rent = LoopOption(kind: .trigger, label: "Rent due")
        rent.createdAt = daysAgo(30)
        let loops = [
            Loop.sample(trigger: OptionChoice(rent), createdAt: daysAgo(3)),
            Loop.sample(trigger: OptionChoice(rent), createdAt: daysAgo(2)),
            loop(.news),
        ]
        rent.isHidden = true
        let whileHidden = OptionRanker(loops: loops, saved: [rent], now: now)
            .triggers(OptionList.choices(for: .trigger, saved: [rent]))
        #expect(!whileHidden.contains { $0.label == "Rent due" })

        rent.isHidden = false
        let ranked = OptionRanker(loops: loops, saved: [rent], now: now)
            .triggers(OptionList.choices(for: .trigger, saved: [rent]))

        #expect(ranked.first?.label == "Rent due")
    }

    /// Two devices can each save the same text; the list shows it once and counts both.
    @Test
    func `two synced copies of the person's own text count as one option`() {
        let first = LoopOption(kind: .trigger, label: "Rent due")
        first.createdAt = daysAgo(40)
        let second = LoopOption(kind: .trigger, label: "Rent due")
        second.createdAt = daysAgo(30)
        let loops = [
            Loop.sample(trigger: OptionChoice(first), createdAt: daysAgo(2)),
            Loop.sample(trigger: OptionChoice(second), createdAt: daysAgo(2)),
            loop(.money),
        ]
        let ranker = OptionRanker(loops: loops, saved: [first, second], now: now)

        let ranked = ranker.triggers(OptionList.choices(for: .trigger, saved: [first, second]))

        #expect(ranked.map(\.label).prefix(2) == ["Rent due", "Money"])
        #expect(ranked.count { $0.label == "Rent due" } == 1)
    }
}

/// Step 2: behaviors ordered for the trigger just picked.
struct OptionRankerBehaviorTests {
    let now = Date(timeIntervalSince1970: 1_790_000_000)
    /// A map of its own, so these tests don't change when the reviewer edits the shipped one.
    let pairs: StarterPairs

    init() throws {
        pairs = try StarterPairs(json: Data(#"{"trigger.news": ["behavior.scrolled", "behavior.keptChecking"]}"#.utf8))
    }

    private func daysAgo(_ days: Double) -> Date {
        now.addingTimeInterval(-days * 24 * 60 * 60)
    }

    private func loop(_ trigger: StarterID, _ behavior: StarterID, daysAgo days: Double = 1) -> Loop {
        .sample(
            trigger: OptionChoice(trigger, label: ""),
            behavior: OptionChoice(behavior, label: ""),
            createdAt: daysAgo(days),
        )
    }

    private func behaviors(after trigger: OptionChoice, loops: [Loop], saved: [LoopOption] = []) -> [StarterID?] {
        let ranker = OptionRanker(loops: loops, saved: saved, now: now)
        let choices = OptionList.choices(for: .behavior, saved: saved)
        return ranker.behaviors(choices, after: trigger, pairs: pairs).map(\.starterID)
    }

    private var starterBehaviors: [StarterID] {
        StarterOption.options(for: .behavior).map(\.id)
    }

    /// Once a trigger has three loops, the person's own pairings say more than any guess.
    @Test
    func `behaviors logged most with this trigger come first, then by how often they're logged at all`() {
        let loops = [
            loop(.work, .scrolled), loop(.work, .scrolled), loop(.work, .snacked),
            loop(.news, .avoidedIt), loop(.news, .avoidedIt), loop(.money, .avoidedIt),
            loop(.money, .snacked),
        ]

        let ranked = behaviors(after: OptionChoice(.work, label: "Work"), loops: loops)

        // Scrolled leads on pairings; Snacked and Avoided it were each paired once or never, so overall use decides.
        #expect(Array(ranked.prefix(3)) == [.scrolled, .snacked, .avoidedIt])
    }

    @Test
    func `with fewer than three loops for the trigger, its starter map comes first, then overall use`() {
        let loops = [loop(.news, .avoidedIt), loop(.money, .avoidedIt), loop(.news, .snacked)]

        let ranked = behaviors(after: OptionChoice(.news, label: "News"), loops: loops)

        #expect(Array(ranked.prefix(4)) == [.scrolled, .keptChecking, .avoidedIt, .snacked])
        #expect(Set(ranked.compactMap(\.self)) == Set(starterBehaviors))
    }

    @Test
    func `with no history at all, the starter map comes first, then the starters in order`() {
        let ranked = behaviors(after: OptionChoice(.news, label: "News"), loops: [])

        #expect(ranked == [.scrolled, .keptChecking] + starterBehaviors
            .filter { ![.scrolled, .keptChecking].contains($0) })
    }

    /// The person's own trigger has no starter map, so overall use leads.
    @Test
    func `the person's own trigger uses the overall order`() {
        let rent = OptionChoice(LoopOption(kind: .trigger, label: "Rent due"))
        let loops = [loop(.money, .avoidedIt), loop(.money, .avoidedIt), loop(.work, .snacked)]

        let ranked = behaviors(after: rent, loops: loops)

        #expect(Array(ranked.prefix(2)) == [.avoidedIt, .snacked])
    }

    @Test
    func `a behavior the person hid is skipped, even when the map lists it`() {
        let hidden = LoopOption(overriding: .scrolled, label: "Scrolled")
        hidden.isHidden = true

        let ranked = behaviors(after: OptionChoice(.news, label: "News"), loops: [], saved: [hidden])

        #expect(ranked.first == .keptChecking)
        #expect(!ranked.contains(.scrolled))
    }

    @Test
    func `the person's own behavior added in the last 7 days comes before the map`() {
        let paced = LoopOption(kind: .behavior, label: "Paced around")
        paced.createdAt = daysAgo(2)

        let ranked = behaviors(after: OptionChoice(.news, label: "News"), loops: [], saved: [paced])

        #expect(Array(ranked.prefix(3)) == [nil, .scrolled, .keptChecking])
    }

    /// Loops under any id the trigger shows count toward its pairings, and toward the three that end the cold start.
    @Test
    func `loops under the trigger's merged ids count as that trigger`() {
        let copy = LoopOption(kind: .trigger, label: "Work")
        copy.createdAt = daysAgo(30)
        let work = OptionList.choices(for: .trigger, saved: [copy]).first { $0.label == "Work" }
        let loops = [
            loop(.work, .snacked), loop(.work, .snacked),
            .sample(trigger: OptionChoice(copy), behavior: OptionChoice(.snacked, label: ""), createdAt: now),
        ]

        let ranked = work.map { behaviors(after: $0, loops: loops) } ?? []

        #expect(ranked.first == .snacked)
    }

    @Test
    func `behaviors logged more than 90 days ago don't count`() {
        let rent = OptionChoice(LoopOption(kind: .trigger, label: "Rent due"))
        let loops = [
            loop(.money, .avoidedIt, daysAgo: 91),
            loop(.money, .avoidedIt, daysAgo: 95),
            loop(.work, .snacked),
        ]

        #expect(behaviors(after: rent, loops: loops).first == .snacked)
    }

    @Test
    func `on a tie, the person's own behaviors come before starters`() {
        let paced = LoopOption(kind: .behavior, label: "Paced around")
        paced.createdAt = daysAgo(30)
        let rent = OptionChoice(LoopOption(kind: .trigger, label: "Rent due"))
        let loops = [
            loop(.money, .snacked),
            .sample(behavior: OptionChoice(paced), createdAt: daysAgo(1)),
        ]

        #expect(Array(behaviors(after: rent, loops: loops, saved: [paced]).prefix(2)) == [nil, .snacked])
    }
}
