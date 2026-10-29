import SwiftUI

struct RootView: View {
    @Bindable var model: RootViewModel

    var body: some View {
        TabView(selection: Binding(get: { model.selectedTab }, set: { model.select($0) })) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView(isLoggerOpen: model.isLogSheetPresented) { tab in
                    model.select(tab)
                }
            }
            Tab("Learn", systemImage: "book", value: .learn) {
                PlaceholderScreen(title: "Learn")
            }
            Tab("Insights", systemImage: "chart.bar", value: .insights) {
                InsightsView {
                    model.select(.log)
                }
            }
            // Selecting this tab opens the sheet; RootViewModel never makes it the selection.
            // Keeps the system's glass look rather than the mockup's accent fill (ADR 0003).
            Tab("Log a loop", systemImage: "square.and.pencil", value: AppTab.log, role: .prominent) {
                Color.clear
            }
        }
        .tint(.theme(.accent))
        .sheet(isPresented: $model.isLogSheetPresented) {
            LogLoopView {
                model.showInsights()
            }
        }
    }
}

/// Stands in for each tab's screen until its milestone lands.
private struct PlaceholderScreen: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.theme(.title))
            .foregroundStyle(.theme(.textPrimary))
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.theme(.background))
    }
}

#if DEBUG
    #Preview {
        RootView(model: RootViewModel())
            .modelContainer(AppModelContainer.preview)
    }
#endif
