@testable import LooseningWorry
import Testing

struct KindPagesTests {
    /// The self-compassion break: notice, a kind touch, then that it's hard, that others feel it, and kindness; then
    /// what you'd say to a friend, and something to take away.
    @Test
    func `the pages go notice, touch, hard, not alone, kindness, friend, take away`() {
        #expect(KindPage.allCases == [.notice, .touch, .hard, .notAlone, .kindness, .friend, .takeAway])
    }

    /// Kind words often feel untrue at first, so each phrase page offers other wordings to find one that rings true.
    @Test(arguments: [KindPage.hard, .notAlone, .kindness])
    func `each phrase page offers three wordings`(page: KindPage) {
        #expect(page.wordings.count == 3)
        #expect(Set(page.wordings.map(\.id)).count == 3)
    }

    @Test(arguments: [KindPage.notice, .touch, .friend, .takeAway])
    func `the other pages have no wordings to choose`(page: KindPage) {
        #expect(page.wordings.isEmpty)
    }

    @Test
    func `the first wordings are the plainest`() {
        #expect(KindPage.hard.wordings.first?.id == .thisIsHard)
        #expect(KindPage.notAlone.wordings.first?.id == .lotsOfPeople)
        #expect(KindPage.kindness.wordings.first?.id == .mayIBeKind)
    }
}
