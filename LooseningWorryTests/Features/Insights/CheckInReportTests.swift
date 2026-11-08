import Foundation
@testable import LooseningWorry
import Testing

struct CheckInReportTests {
    /// Weeks start on Monday here, as in Australia; the report follows the person's own calendar.
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney") ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Wednesday 28 October 2026, 3 pm.
    var now: Date {
        date(day: 28, hour: 15)
    }

    func date(day: Int, hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)) ?? .distantPast
    }

    func checkIn(
        _ pleasantness: Pleasantness,
        _ feelings: [Feeling] = [],
        contexts: [OptionChoice] = [],
        at createdAt: Date? = nil,
    ) -> CheckIn {
        let checkIn = CheckIn(CheckInAnswer(pleasantness: pleasantness, feelings: feelings, contexts: contexts))
        checkIn.createdAt = createdAt ?? date(day: 27, hour: 9)
        return checkIn
    }

    func report(_ checkIns: [CheckIn], period: InsightsPeriod = .thisWeek, saved: [LoopOption] = []) -> CheckInReport {
        CheckInReport(checkIns: checkIns, saved: saved, period: period, now: now, calendar: calendar)
    }

    @Test
    func `only check-ins in the period, up to now, count`() {
        let checkIns = [
            checkIn(.unpleasant, at: date(day: 26, hour: 8)),
            checkIn(.pleasant, at: date(day: 28, hour: 14)),
            checkIn(.neutral, at: date(day: 25, hour: 23)), // last Sunday: last week
            checkIn(.neutral, at: date(day: 28, hour: 16)), // later today: not yet
        ]

        #expect(report(checkIns).total == 2)
        #expect(report(checkIns, period: .lastFourWeeks).total == 3)
    }

    /// One or two check-ins say little, so the cards wait for five, as "Most loops start…" does.
    @Test
    func `the cards wait for five check-ins`() {
        let four = Array(repeating: Pleasantness.neutral, count: 4).map { checkIn($0) }

        #expect(!report(four).hasEnough)
        #expect(report(four + [checkIn(.pleasant)]).hasEnough)
    }

    /// The three slightly-to-very steps on each side count as that side.
    @Test
    func `how the check-ins felt is counted by side`() {
        let checkIns = [Pleasantness.veryUnpleasant, .slightlyUnpleasant, .unpleasant, .neutral, .slightlyPleasant]
            .map { checkIn($0) }

        let felt = report(checkIns).felt

        #expect(felt == CheckInReport.Felt(unpleasant: 3, neutral: 1, pleasant: 1))
    }

    @Test
    func `the words named most come first, five at most, ties alphabetical`() {
        let checkIns = [
            checkIn(.unpleasant, [.worried, .anxious, .drained]),
            checkIn(.unpleasant, [.anxious, .stressed]),
            checkIn(.unpleasant, [.anxious, .worried]),
            checkIn(.pleasant, [.calm, .content]),
            checkIn(.neutral, [.calm, .indifferent]),
        ]

        let named = report(checkIns).namedFeelings

        #expect(named.map(\.feeling) == [.anxious, .calm, .worried, .content, .drained])
        #expect(named.map(\.count) == [3, 2, 2, 1, 1])
    }

    static let work = OptionChoice(.contextWork, label: "Work")
    static let money = OptionChoice(.contextMoney, label: "Money")
    static let family = OptionChoice(.contextFamily, label: "Family")
    static let health = OptionChoice(.contextHealth, label: "Health")
    static let friends = OptionChoice(.contextFriends, label: "Friends")

    /// "Work: 3 of 4 check-ins", out of every unpleasant check-in, those with no context too.
    @Test
    func `what weighs on you: contexts on unpleasant check-ins, most first, three at most`() {
        let checkIns = [
            checkIn(.unpleasant, contexts: [Self.work, Self.money]),
            checkIn(.veryUnpleasant, contexts: [Self.work, Self.family]),
            checkIn(.slightlyUnpleasant, contexts: [Self.work, Self.health, Self.money]),
            checkIn(.unpleasant),
            checkIn(.pleasant, contexts: [Self.friends]),
        ]

        let weighs = report(checkIns).weighs

        #expect(weighs.map(\.label) == ["Work", "Money", "Family"])
        #expect(weighs.map(\.share.count) == [3, 2, 1])
        #expect(weighs.allSatisfy { $0.share.total == 4 })
    }

    /// Neutral check-ins neither weigh nor lift, so their contexts count on neither side.
    @Test
    func `what lifts you: contexts on pleasant check-ins, neutral ones on neither side`() {
        let checkIns = [
            checkIn(.pleasant, contexts: [Self.friends]),
            checkIn(.veryPleasant, contexts: [Self.friends, Self.health]),
            checkIn(.neutral, contexts: [Self.work, Self.friends]),
        ]

        let report = report(checkIns)

        #expect(report.lifts == [
            CheckInReport.ContextShare(id: "context.friends", label: "Friends", share: Share(count: 2, total: 2)),
            CheckInReport.ContextShare(id: "context.health", label: "Health", share: Share(count: 1, total: 2)),
        ])
        #expect(report.weighs.isEmpty)
    }

    /// Two devices can each save "Moving house"; the check-in shows one chip for both, so Insights counts one context.
    @Test
    func `copies of one context count as one`() {
        let copyA = LoopOption(kind: .context, label: "Moving house")
        let copyB = LoopOption(kind: .context, label: "Moving house")
        let checkIns = [
            checkIn(.unpleasant, contexts: [OptionChoice(copyA)]),
            checkIn(.unpleasant, contexts: [OptionChoice(copyB)]),
        ]

        let weighs = report(checkIns, saved: [copyA, copyB]).weighs

        #expect(weighs.map(\.label) == ["Moving house"])
        #expect(weighs.map(\.share.count) == [2])
    }

    /// "check-in" is a plural written by hand in the catalog, so only the catalog can give the singular.
    @Test(arguments: [(1, "1 check-in this week"), (16, "16 check-ins this week")])
    func `the total says check-in or check-ins`(count: Int, line: String) {
        let checkIns = Array(repeating: Pleasantness.neutral, count: count).map { checkIn($0) }

        #expect(String(localized: report(checkIns).totalLine) == line)
    }

    @Test(arguments: [(1, 1, "1 of 1 check-in"), (3, 7, "3 of 7 check-ins")])
    func `a context's line counts out of its side's check-ins`(count: Int, total: Int, line: String) {
        let share = CheckInReport.ContextShare(
            id: "context.work",
            label: "Work",
            share: Share(count: count, total: total),
        )

        #expect(String(localized: share.line) == line)
    }

    /// A check-in can hold two copies of one context, picked before sync merged them; it's still one check-in.
    @Test
    func `a check-in counts a context once, whichever copies it holds`() {
        let copyA = LoopOption(kind: .context, label: "Moving house")
        let copyB = LoopOption(kind: .context, label: "Moving house")
        let checkIns = [checkIn(.unpleasant, contexts: [OptionChoice(copyA), OptionChoice(copyB)])]

        let weighs = report(checkIns, saved: [copyA, copyB]).weighs

        #expect(weighs.map(\.share.count) == [1])
        #expect(weighs.map(\.share.total) == [1])
    }

    /// The Removed list shows hidden copies as one, so Insights counts them as one too.
    @Test
    func `removed copies of one context still count as one`() {
        let copyA = LoopOption(kind: .context, label: "Moving house")
        let copyB = LoopOption(kind: .context, label: "Moving house")
        copyA.isHidden = true
        copyB.isHidden = true
        let checkIns = [
            checkIn(.unpleasant, contexts: [OptionChoice(copyA)]),
            checkIn(.unpleasant, contexts: [OptionChoice(copyB)]),
        ]

        let weighs = report(checkIns, saved: [copyA, copyB]).weighs

        #expect(weighs.map(\.label) == ["Moving house"])
        #expect(weighs.map(\.share.count) == [2])
    }

    /// A check-in from a newer version can hold a step this one doesn't know. Counting it in the total but on no side
    /// would leave the bar short and the sides adding up to less than the total, so it's left out.
    @Test
    func `a check-in this version can't place on a side is left out`() {
        let unknown = checkIn(.neutral)
        unknown.pleasantnessID = "addedLater"

        let report = report([checkIn(.pleasant), unknown])

        #expect(report.total == 1)
        #expect(report.felt == CheckInReport.Felt(unpleasant: 0, neutral: 0, pleasant: 1))
    }

    @Test
    func `contexts picked as often are listed alphabetically`() {
        let checkIns = [checkIn(.pleasant, contexts: [Self.money, Self.family, Self.work])]

        #expect(report(checkIns).lifts.map(\.label) == ["Family", "Money", "Work"])
    }

    /// A deleted context has no option left, so its past check-ins keep its own id and the text they were picked
    /// with.
    @Test
    func `a deleted context keeps its own row and text`() {
        let checkIns = [checkIn(.unpleasant, contexts: [OptionChoice(id: "custom.gone", label: "Old flat")])]

        #expect(report(checkIns).weighs == [
            CheckInReport.ContextShare(id: "custom.gone", label: "Old flat", share: Share(count: 1, total: 1))
        ])
    }

    /// Adding a deleted context's text again brings it back under its old id, so its past check-ins count with the
    /// new ones.
    @Test
    func `a context brought back after a delete counts with its past check-ins`() {
        let back = LoopOption(kind: .context, label: "Moving house")
        back.optionID = "custom.old"
        let checkIns = [
            checkIn(.unpleasant, contexts: [OptionChoice(id: "custom.old", label: "Moving house")]),
            checkIn(.unpleasant, contexts: [OptionChoice(back)]),
        ]

        #expect(report(checkIns, saved: [back]).weighs.map(\.share.count) == [2])
    }
}
