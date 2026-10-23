import Observation

enum AppTab: Hashable {
    case home, learn, insights
    /// An action, not a destination: `RootViewModel` never makes it the selection.
    case log
}

@Observable @MainActor
final class RootViewModel {
    private(set) var selectedTab: AppTab = .home
    var isLogSheetPresented = false

    /// Log is an action, not a destination: it opens the sheet over whichever tab is showing.
    func select(_ tab: AppTab) {
        if tab == .log {
            isLogSheetPresented = true
        } else {
            selectedTab = tab
        }
    }
}
