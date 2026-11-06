@testable import LooseningWorry
import Testing

struct TriggerSummaryTests {
    @Test
    func `a row's sentence says how often, as words`() {
        #expect(String(localized: TriggerSummary.Line.metWithTool(2, of: 6).sentence)
            == "Met it with a tool 2 of 6 times")
        #expect(String(localized: TriggerSummary.Line.habit(label: "Kept checking", count: 4).sentence)
            == "Kept checking 4 times")
    }

    /// The source's own wording always says "times"; "time" comes only from the catalog's plural.
    @Test
    func `once reads as one time`() {
        #expect(String(localized: TriggerSummary.Line.metWithTool(1, of: 1).sentence)
            == "Met it with a tool 1 of 1 time")
        #expect(String(localized: TriggerSummary.Line.habit(label: "Kept checking", count: 1).sentence)
            == "Kept checking 1 time")
    }

    /// The page's lines count with the same hand-written plurals.
    @Test
    func `the page's lines read one as one time`() throws {
        let one = InsightsReport.Share(count: 1, total: 1)
        #expect(String(localized: one.noBetterLine) == "no better 1 of 1 time")
        #expect(String(localized: one.lighterLine) == "lighter 1 of 1 time")
        #expect(String(localized: InsightsReport.Share(count: 5, total: 6).noBetterLine) == "no better 5 of 6 times")

        let loop = Loop.sample(createdAt: .now, noticed: .whileHappening)
        let detail = try #require(InsightsReport(
            loops: [loop],
            saved: [],
            period: .thisWeek,
            now: .now,
            calendar: .current,
        ).trigger("trigger.work"))
        #expect(String(localized: detail.totalLine(in: .thisWeek)) == "1 time this week")
        #expect(String(localized: detail.totalLine(in: .lastFourWeeks)) == "1 time in the last 4 weeks")
        #expect(String(localized: detail.noticedLine) == "While it was happening 1 of the last 1 time")
    }
}
