import SwiftUI

/// A flow's main button, pinned to the bottom, with a note above it when the last try failed: the logger's Save, the
/// check-in's Next and Done.
struct PrimaryActionBar: View {
    let title: LocalizedStringResource
    /// Shown above the button when set. The screen announces it when it appears, so VoiceOver skips it here.
    let failure: LocalizedStringResource?
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if let failure {
                Text(failure)
                    .font(.theme(.caption))
                    // `redStrong` is too light for small text on the page; the on-tint red is dark enough on it too.
                    .foregroundStyle(.theme(.redOnTint))
                    .accessibilityHidden(true)
            }
            Button(action: action) {
                Text(title)
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textOnAccent))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(.theme(.accent), in: .capsule)
                    .shadow(color: .theme(.accentShadow).opacity(0.3), radius: 8, y: 6)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.theme(.background))
    }
}
