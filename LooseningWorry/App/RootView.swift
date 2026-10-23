import SwiftUI

/// Placeholder until the first feature screen lands.
struct RootView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Loosening Worry")
                .font(.theme(.title))
                .foregroundStyle(.theme(.textPrimary))
            Text("Notice the loop. Get curious. Let it loosen.")
                .font(.theme(.body))
                .foregroundStyle(.theme(.textSecondary))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.theme(.background))
    }
}

#Preview {
    RootView()
}
