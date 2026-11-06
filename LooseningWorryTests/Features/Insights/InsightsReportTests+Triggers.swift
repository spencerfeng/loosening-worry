import Foundation
@testable import LooseningWorry
import Testing

/// "What sets you off" and each trigger's page.
extension InsightsReportTests {
    static let curious = ("tool.curious", "Got curious")

    /// Every trigger gets a row, since each opens its own page: what the person did after it, the habit or a tool.
    @Test
    func `each trigger counts the habits and the tools that followed it, most logged first`() {
        let loops = [
            loop(date(day: 26, hour: 8), trigger: ("trigger.money", "Money")),
            loop(date(day: 26, hour: 9)),
            loop(date(day: 27, hour: 9), behavior: Self.curious, result: ("outcome.lighter", "Lighter")),
            loop(date(day: 27, hour: 10)),
        ]

        let triggers = report(loops).triggers

        #expect(triggers.map(\.label) == ["Work", "Money"])
        #expect(triggers.map(\.habits) == [2, 1])
        #expect(triggers.map(\.metWithTool) == [1, 0])
    }

    /// A row with no tool yet names the habit the trigger led to most, for "Kept checking 4 times".
    @Test
    func `each trigger names the habit it led to most`() {
        let checked = ("behavior.keptChecking", "Kept checking")
        let loops = [
            loop(date(day: 26, hour: 8), behavior: checked),
            loop(date(day: 26, hour: 9), behavior: checked),
            loop(date(day: 27, hour: 9)),
            loop(date(day: 27, hour: 10), behavior: Self.curious, result: ("outcome.lighter", "Lighter")),
            loop(date(day: 27, hour: 11), behavior: Self.curious, result: ("outcome.lighter", "Lighter")),
            loop(date(day: 27, hour: 12), behavior: Self.curious, result: ("outcome.lighter", "Lighter")),
        ]

        let habit = report(loops).triggers.first?.topHabit

        #expect(habit?.label == "Kept checking")
        #expect(habit?.count == 2)
    }

    /// Meeting the urge is the progress that matters, so once a trigger has been met with a tool its row says how
    /// often; until then it names the habit.
    @Test
    func `a row speaks of meeting the urge once it has, and of the habit until then`() {
        let checked = ("behavior.keptChecking", "Kept checking")
        let loops = [
            loop(date(day: 26, hour: 8), trigger: ("trigger.money", "Money"), behavior: checked),
            loop(date(day: 26, hour: 9)),
            loop(date(day: 27, hour: 9), behavior: Self.curious, result: ("outcome.lighter", "Lighter")),
            loop(date(day: 27, hour: 10)),
        ]

        let rows = report(loops).triggers

        #expect(rows.first?.line == .metWithTool(1, of: 3))
        #expect(rows.last?.line == .habit(label: "Kept checking", count: 1))
    }

    @Test
    func `a trigger's detail counts each habit and tool that followed it, most first`() throws {
        let checked = ("behavior.keptChecking", "Kept checking")
        let loops = [
            loop(date(day: 26, hour: 8)),
            loop(date(day: 26, hour: 9)),
            loop(date(day: 26, hour: 10), behavior: checked),
            loop(date(day: 27, hour: 9), behavior: Self.curious, result: ("outcome.lighter", "Lighter")),
            loop(date(day: 27, hour: 10), trigger: ("trigger.money", "Money"), behavior: checked),
        ]

        let page = try #require(report(loops).trigger("trigger.work"))

        #expect(page.label == "Work")
        #expect(page.total == 4)
        #expect(page.followedBy.map(\.label) == ["Overthought it", "Got curious", "Kept checking"])
        #expect(page.followedBy.map(\.count) == [2, 1, 1])
        #expect(page.followedBy.map(\.isTool) == [false, true, false])
    }

    /// The old way and the new way side by side. As on the habit card, "Not sure" and the person's own results say
    /// nothing either way; for a tool, neither does a run left unanswered.
    @Test
    func `a trigger's detail compares what the habits and the tools gave`() throws {
        let loops = [
            loop(date(day: 26, hour: 8), result: ("result.moreWorry", "More worry")),
            loop(date(day: 26, hour: 9), result: ("result.nothingChanged", "Nothing changed")),
            loop(date(day: 26, hour: 10), result: ("result.littleRelief", "A little relief")),
            loop(date(day: 26, hour: 11), result: ("result.notSure", "Not sure")),
            loop(date(day: 27, hour: 9), behavior: Self.curious, result: ("outcome.lighter", "Lighter")),
            loop(date(day: 27, hour: 10), behavior: Self.curious, result: ("outcome.same", "About the same")),
            loop(date(day: 27, hour: 11), behavior: Self.curious, result: ("result.notSure", "Not sure")),
        ]

        let page = try #require(report(loops).trigger("trigger.work"))

        #expect(page.habitsNoBetter == InsightsReport.Share(count: 2, total: 3))
        #expect(page.toolsLighter == InsightsReport.Share(count: 1, total: 2))
    }

    /// Noticing earlier is the progress the dots show: the habits only, since meeting the urge with a tool comes before
    /// any habit runs.
    @Test
    func `a trigger's detail shows when the last eight habits were noticed, oldest first`() throws {
        let answers: [NoticeTiming?] = [
            .afterwards, .afterwards, nil, .afterwards, .whileHappening, .afterwards, .whileHappening, .whileHappening,
            .afterwards, .whileHappening,
        ]
        var loops = answers.enumerated().map { hour, answer in
            let habit = loop(date(day: 26, hour: hour + 1))
            habit.noticed = answer
            return habit
        }
        let met = loop(date(day: 27, hour: 9), behavior: Self.curious, result: ("outcome.lighter", "Lighter"))
        met.noticed = .whileHappening
        loops.append(met)

        let page = try #require(report(loops).trigger("trigger.work"))

        #expect(page.noticed == [
            .afterwards, .afterwards, .whileHappening, .afterwards, .whileHappening, .whileHappening, .afterwards,
            .whileHappening,
        ])
    }

    @Test
    func `a trigger's detail keeps the latest three notes, newest first, with what they were about`() throws {
        let notes = ["Inbox dread", nil, "Ran the meeting in my head", "Awake till 2", "Chest tight before the 1:1"]
        let loops = notes.enumerated().map { hour, note in
            let noted = loop(date(day: 26, hour: hour + 1), result: ("result.tenseAndTired", "Tense and tired"))
            noted.note = note
            return noted
        }

        let page = try #require(report(loops).trigger("trigger.work"))

        #expect(page.notes.map(\.text) == ["Chest tight before the 1:1", "Awake till 2", "Ran the meeting in my head"])
        #expect(page.notes.first?.behavior == "Overthought it")
        #expect(page.notes.first?.result == "Tense and tired")
        #expect(page.notes.first?.date == date(day: 26, hour: 5))
    }

    /// The page opens from a row, by the id the row gives: copies of the trigger, and of a habit, are one.
    @Test
    func `a trigger's detail counts copies of the trigger and of a habit as one`() throws {
        let ownTrigger = LoopOption(kind: .trigger, label: "Work")
        let ownHabit = LoopOption(kind: .behavior, label: "Overthought it")
        let loops = [
            loop(date(day: 26, hour: 8)),
            loop(
                date(day: 27, hour: 8),
                trigger: (ownTrigger.optionID, "Work"),
                behavior: (ownHabit.optionID, "Overthought it"),
            ),
        ]

        let detail = try #require(report(loops, saved: [ownTrigger, ownHabit]).trigger("trigger.work"))

        #expect(detail.total == 2)
        #expect(detail.followedBy.map(\.count) == [2])
    }

    /// Each part of the page shows only once it has something to say.
    @Test
    func `a trigger's detail says nothing it has no loops for`() throws {
        let loops = [loop(date(day: 26, hour: 8), result: ("result.notSure", "Not sure"))]
        let report = report(loops)

        let detail = try #require(report.trigger("trigger.work"))
        #expect(detail.habitsNoBetter == nil)
        #expect(detail.toolsLighter == nil)
        #expect(detail.noticed.isEmpty)
        #expect(detail.notes.isEmpty)
        #expect(report.trigger("trigger.money") == nil)
    }
}
