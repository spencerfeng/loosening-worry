import SwiftUI

/// Shows the rest of a list of chips, in the same order. It goes once they're showing.
struct MoreChip: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(LocalizedStringResource("option.more", defaultValue: "More"))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .accessibilityHidden(true)
            }
            .font(.theme(.headline))
            .foregroundStyle(.theme(.textSecondary))
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .overlay { Capsule().strokeBorder(.theme(.border)) }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(LocalizedStringResource(
            "option.more.hint",
            defaultValue: "Shows the rest of the list",
        )))
    }
}
