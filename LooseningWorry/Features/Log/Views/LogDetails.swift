import SwiftUI

/// Once every step is answered: a link that opens the optional details, and the details themselves.
///
/// Like `LogQuestion`, it takes values rather than the view model, so it shows what it last showed while it leaves.
struct LogDetails: View {
    let isShowing: Bool
    let anxiety: Int?
    @Binding var note: String
    let toggle: () -> Void
    let setAnxiety: (Int) -> Void

    private static let toggleLabel = LocalizedStringResource(
        "log.details.toggle",
        defaultValue: "Add details (optional)",
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: toggle) {
                // The plus is drawn, so VoiceOver reads just the words.
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                        .accessibilityHidden(true)
                    Text(Self.toggleLabel)
                }
                .font(.theme(.callout))
                .foregroundStyle(.theme(.accentText))
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isShowing ? Text("Open") : Text("Closed"))

            if isShowing {
                LogDetailsCard(anxiety: anxiety, note: $note, setAnxiety: setAnxiety)
                    .transition(.opacity)
            }
        }
    }
}

/// How anxious the person felt and a note, both optional.
private struct LogDetailsCard: View {
    let anxiety: Int?
    @Binding var note: String
    let setAnxiety: (Int) -> Void

    private static let anxietyLabel = LocalizedStringResource(
        "log.details.anxiety",
        defaultValue: "How anxious, 0–10",
    )
    private static let anxietyNotSet = LocalizedStringResource("log.details.anxietyNotSet", defaultValue: "Not set")
    private static let noteLabel = LocalizedStringResource("log.details.note", defaultValue: "Note")
    private static let notePlaceholder = LocalizedStringResource(
        "log.details.notePlaceholder",
        defaultValue: "Anything worth remembering",
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                // VoiceOver reads the label and the level from the slider instead.
                HStack(alignment: .firstTextBaseline) {
                    Text(Self.anxietyLabel)
                        .font(.theme(.footnote))
                        .fontWeight(.bold)
                        .foregroundStyle(.theme(.textSecondary))
                    Spacer()
                    Group {
                        if let anxiety {
                            Text(anxiety, format: .number)
                        } else {
                            Text(verbatim: "–")
                        }
                    }
                    .font(.theme(.title2))
                    .monospacedDigit()
                    .foregroundStyle(.theme(.violetStrong))
                }
                .accessibilityHidden(true)

                Slider(value: anxietyLevel, in: anxietyRange, step: 1) {
                    Text(Self.anxietyLabel)
                }
                .tint(.theme(.violetStrong))
                .frame(minHeight: 32)
                .accessibilityValue(anxietyValue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(Self.noteLabel)
                    .font(.theme(.footnote))
                    .fontWeight(.bold)
                    .foregroundStyle(.theme(.textSecondary))
                    // The field carries the same label for VoiceOver.
                    .accessibilityHidden(true)
                TextField(text: $note, prompt: Text(Self.notePlaceholder)) {
                    Text(Self.noteLabel)
                }
                // Return closes the keyboard, so the Save button is in reach again.
                .submitLabel(.done)
                .font(.theme(.body))
                .foregroundStyle(.theme(.textPrimary))
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
                .background(.theme(.background), in: .rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.theme(.border)) }
            }
        }
        .padding(16)
        .background(.theme(.surface), in: .rect(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.theme(.borderSubtle)) }
    }

    private var anxietyRange: ClosedRange<Double> {
        let levels = LogLoopViewModel.anxietyRange
        return Double(levels.lowerBound) ... Double(levels.upperBound)
    }

    /// An unset level rests the thumb in the middle; only moving it records a level.
    private var anxietyLevel: Binding<Double> {
        Binding {
            anxiety.map(Double.init) ?? (anxietyRange.lowerBound + anxietyRange.upperBound) / 2
        } set: { level in
            setAnxiety(Int(level.rounded()))
        }
    }

    private var anxietyValue: Text {
        if let anxiety {
            Text(anxiety, format: .number)
        } else {
            Text(Self.anxietyNotSet)
        }
    }
}
