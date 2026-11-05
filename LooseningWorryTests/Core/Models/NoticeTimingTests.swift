@testable import LooseningWorry
import Testing

struct NoticeTimingTests {
    /// Nice catch calls out noticing earlier, so the order must run from latest to earliest.
    @Test
    func `answers run from noticing latest to noticing earliest`() {
        #expect(NoticeTiming.allCases.sorted() == [.afterwards, .partway, .asItStarted])
        #expect(NoticeTiming.afterwards < .partway)
        #expect(NoticeTiming.partway < .asItStarted)
    }

    /// A loop stores these, so none may change once released.
    @Test
    func `each answer has a stable id`() {
        #expect(NoticeTiming.allCases.map(\.rawValue) == ["afterwards", "partway", "asItStarted"])
    }

    /// A loop synced from a newer version may hold an answer this one doesn't know.
    @Test
    func `an answer this version doesn't know reads as no answer`() {
        let loop = Loop.sample()
        loop.noticedID = "beforeItStarted"

        #expect(loop.noticed == nil)
    }
}
