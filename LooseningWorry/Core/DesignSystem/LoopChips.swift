import SwiftUI

/// The loop as three chips joined by arrows. VoiceOver reads the three in order.
struct LoopChips: View {
    let labels: [String]

    var body: some View {
        FlowLayout(spacing: 6, alignment: .center) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index > 0 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.theme(.textTertiary))
                        .frame(height: 28)
                }
                Text(label)
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.accentPressed))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(.theme(.accentTint), in: .rect(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(labels.joined(separator: ", ")))
    }
}
