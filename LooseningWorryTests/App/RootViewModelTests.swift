@testable import LooseningWorry
import Testing

@MainActor
struct RootViewModelTests {
    @Test
    func `starts on Home with the Log sheet closed`() {
        let model = RootViewModel()

        #expect(model.selectedTab == .home)
        #expect(model.isLogSheetPresented == false)
    }

    @Test(arguments: [AppTab.learn, .insights, .home])
    func `selecting a destination tab switches to it`(tab: AppTab) {
        let model = RootViewModel()

        model.select(.learn)
        model.select(tab)

        #expect(model.selectedTab == tab)
        #expect(model.isLogSheetPresented == false)
    }

    @Test
    func `selecting Log opens the sheet without leaving the current tab`() {
        let model = RootViewModel()
        model.select(.insights)

        model.select(.log)

        #expect(model.isLogSheetPresented)
        #expect(model.selectedTab == .insights)
    }

    @Test
    func `closing the Log sheet returns to the tab it opened over`() {
        let model = RootViewModel()
        model.select(.insights)
        model.select(.log)

        model.isLogSheetPresented = false

        #expect(model.selectedTab == .insights)
    }
}
