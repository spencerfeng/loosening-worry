import SwiftUI

/// Save, pinned under the questions once every step is answered, with a note above it if the last try failed.
struct LogSaveBar: View {
    let failed: Bool
    let canSave: Bool
    let save: () -> Void

    static let failedMessage = LocalizedStringResource(
        "log.save.failed",
        defaultValue: "Couldn't save this loop. Please try again.",
    )

    var body: some View {
        VStack(spacing: 8) {
            if failed {
                Text(Self.failedMessage)
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.redStrong))
                    // Announced when it appears.
                    .accessibilityHidden(true)
            }
            Button(action: save) {
                Text(LocalizedStringResource("log.save", defaultValue: "Save loop"))
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textOnAccent))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(.theme(.accent), in: .capsule)
                    .shadow(color: .theme(.accentShadow).opacity(0.3), radius: 8, y: 6)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.theme(.background))
    }
}
