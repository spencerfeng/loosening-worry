import SwiftUI

/// Where the person can describe the whole loop in their own words instead of picking each step. One line that grows as
/// they type, up to four, with a round Fill in button once there are words. The line under it says the words are kept
/// private while typing, then what Fill in is doing.
struct LogDescribeField: View {
    @Binding var text: String
    let canFillIn: Bool
    let isFillingIn: Bool
    let couldntTell: Bool
    let fillIn: () -> Void
    @FocusState private var isFocused: Bool

    static let couldntTellMessage = LocalizedStringResource(
        "log.describe.couldntTell",
        defaultValue: "Couldn't tell from that. Pick below, or try other words.",
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                TextField(
                    text: $text,
                    prompt: Text(LocalizedStringResource(
                        "log.describe.placeholder",
                        defaultValue: "Describe it to fill in the steps",
                    )),
                    axis: .vertical,
                ) {
                    Text(LocalizedStringResource("log.describe.label", defaultValue: "Describe what happened"))
                }
                .lineLimit(1 ... 4)
                .font(.theme(.body))
                .foregroundStyle(.theme(.textPrimary))
                .opacity(isFillingIn ? 0.6 : 1)
                .disabled(isFillingIn)
                .focused($isFocused)
                .padding(.vertical, 4)
                if hasWords || isFillingIn {
                    fillInButton
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .frame(minHeight: 48)
            .cardSurface(
                cornerRadius: 24,
                outline: isFocused || isFillingIn ? .accent : .border,
                lineWidth: isFocused || isFillingIn ? 1.5 : 1,
            )
            .contentShape(.rect(cornerRadius: 24))
            .onTapGesture { isFocused = true }
            status
                .padding(.horizontal, 16)
        }
    }

    private var hasWords: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var fillInButton: some View {
        Button {
            isFocused = false
            fillIn()
        } label: {
            ZStack {
                Circle().fill(.theme(.accentFill))
                if isFillingIn {
                    ProgressView()
                        .tint(.theme(.textOnAccent))
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.theme(.textOnAccent))
                }
            }
            .frame(width: 32, height: 32)
            .opacity(isFillingIn ? 0.75 : 1)
            // The circle is drawn small; the tap area reaches 44 points.
            .frame(width: 44, height: 44)
            .contentShape(.rect)
            .padding(-6)
        }
        .buttonStyle(.plain)
        .disabled(!canFillIn)
        .accessibilityLabel(Text(LocalizedStringResource("log.describe.fillIn", defaultValue: "Fill in")))
    }

    @ViewBuilder private var status: some View {
        if isFillingIn {
            Text(LocalizedStringResource("log.describe.fillingIn", defaultValue: "Filling in…"))
                .font(.theme(.footnote))
                .foregroundStyle(.theme(.textTertiary))
        } else if couldntTell {
            Text(Self.couldntTellMessage)
                .font(.theme(.caption))
                .foregroundStyle(.theme(.textSecondary))
        } else if isFocused {
            Label {
                Text(LocalizedStringResource("log.describe.private", defaultValue: "Private to you. Never stored."))
            } icon: {
                Image(systemName: "lock")
                    .font(.system(size: 11, weight: .semibold))
            }
            .labelStyle(.titleAndIcon)
            .font(.theme(.caption))
            .foregroundStyle(.theme(.textTertiary))
        }
    }
}

/// Splits describing from picking, so the two read as either-or rather than one step after the other.
struct LogOrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            line
            Text(LocalizedStringResource("log.describe.or", defaultValue: "or pick each step"))
                .font(.theme(.footnote))
                .foregroundStyle(.theme(.textTertiary))
                .fixedSize()
            line
        }
        .accessibilityHidden(true)
    }

    private var line: some View {
        Rectangle()
            .fill(.theme(.border))
            .frame(height: 1)
    }
}
