import SwiftUI

/// The title of a step-by-step flow over where it's up to, such as "Log a loop" over "Step 2 of 3". Read as one
/// header.
struct FlowHeader: View {
    let title: LocalizedStringResource
    let detail: LocalizedStringResource

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textPrimary))
            Text(detail)
                .font(.theme(.footnote))
                .foregroundStyle(.theme(.textSecondary))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
