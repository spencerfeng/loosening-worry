import SwiftUI

/// A tool to try, as a card that starts it: its icon, its name and a line about it. Nice catch's suggestion and the
/// check-in's.
struct ToolCard: View {
    let tool: QuickTool
    let detail: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
        HStack(spacing: 12) {
            Image(systemName: tool.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.theme(tool.ink))
                .frame(width: 40, height: 40)
                .background(.theme(tool.tint), in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(tool.name)
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textPrimary))
                Text(detail)
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textTertiary))
            }
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(minHeight: 64)
        .background(.theme(.surface), in: .rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.theme(.borderSubtle)) }
        .contentShape(.rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}
