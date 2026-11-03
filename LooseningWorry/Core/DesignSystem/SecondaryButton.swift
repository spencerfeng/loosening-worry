import SwiftUI

/// A full-width outlined button for the quieter way out, such as Done under a suggested tool.
struct SecondaryButton: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textPrimary))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.theme(.surface), in: .capsule)
                .overlay { Capsule().strokeBorder(.theme(.border)) }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}
