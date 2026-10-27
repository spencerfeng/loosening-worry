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

    /// Nice catch's weekly count leads to Insights, closing the logger on the way.
    @Test
    func `showing Insights from the logger closes it and switches to Insights`() {
        let model = RootViewModel()
        model.select(.log)

        model.showInsights()

        #expect(model.isLogSheetPresented == false)
        #expect(model.selectedTab == .insights)
    }

    @Test
    func `tapping the daily reminder opens the logger`() {
        let model = RootViewModel()
        model.select(.learn)

        model.openNotification(identifier: ReminderNotification.identifier)

        #expect(model.isLogSheetPresented)
        #expect(model.selectedTab == .learn)
    }

    @Test
    func `tapping any other notification leaves the app as it was`() {
        let model = RootViewModel()

        model.openNotification(identifier: "something.else")

        #expect(model.isLogSheetPresented == false)
        #expect(model.selectedTab == .home)
    }
}
