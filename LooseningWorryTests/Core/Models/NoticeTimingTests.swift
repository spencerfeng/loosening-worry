@testable import LooseningWorry
import Testing

struct NoticeTimingTests {
    /// A logged loop means the habit ran, so the person either noticed once it was over or while they were still in it.
    /// Catching the urge as it starts is "Nothing yet", not an answer here.
    @Test
    func `the person noticed afterwards or while it was happening`() {
        #expect(NoticeTiming.allCases == [.afterwards, .whileHappening])
        #expect(NoticeTiming.allCases.map { String(localized: $0.label) } == ["Afterwards", "While it was happening"])
    }

    /// A loop stores these, so none may change once released.
    @Test
    func `each answer has a stable id`() {
        #expect(NoticeTiming.allCases.map(\.rawValue) == ["afterwards", "whileHappening"])
    }

    /// A loop synced from a newer version may hold an answer this one doesn't know.
    @Test
    func `an answer this version doesn't know reads as no answer`() {
        let loop = Loop.sample()
        loop.noticedID = "beforeItStarted"

        #expect(loop.noticed == nil)
    }
}
