import SwiftUI

struct RootView: View {
    @State private var model = RootViewModel()

    var body: some View {
        TabView(selection: Binding(get: { model.selectedTab }, set: { model.select($0) })) {
            Tab("Home", systemImage: "house", value: .home) {
                PlaceholderScreen(title: "Home")
            }
            Tab("Learn", systemImage: "book", value: .learn) {
                PlaceholderScreen(title: "Learn")
            }
            Tab("Insights", systemImage: "chart.bar", value: .insights) {
                PlaceholderScreen(title: "Insights")
            }
            // Selecting this tab opens the sheet; RootViewModel never makes it the selection.
            // Keeps the system's glass look rather than the mockup's accent fill (ADR 0003).
            Tab("Log a loop", systemImage: "square.and.pencil", value: AppTab.log, role: .prominent) {
                Color.clear
            }
        }
        .tint(.theme(.accent))
        .sheet(isPresented: $model.isLogSheetPresented) {
            LogSheetPlaceholder()
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

/// Stands in for the Log a loop flow until M2.
private struct LogSheetPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PlaceholderScreen(title: "Log a loop")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) { dismiss() }
                    }
                }
        }
    }
}

#if DEBUG
    #Preview {
        RootView()
            .modelContainer(AppModelContainer.preview)
    }
#endif
