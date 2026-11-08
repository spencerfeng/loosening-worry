import SwiftUI

/// Once every step is answered: a link that opens the optional details, and the details themselves.
///
/// Like `LogQuestion`, it takes values rather than the view model, so it shows what it last showed while it leaves.
struct LogDetails: View {
    /// Scroll target for the note field, so the logger can keep what's being typed above the keyboard as it grows.
    static let noteFieldID = "LogDetails.noteField"

    let isShowing: Bool
    let anxiety: Int?
    @Binding var note: String
    let toggle: () -> Void
    let setAnxiety: (Int) -> Void
    /// Called when the note field grows a line, so the logger can bring its new last line into view.
    let noteGrew: () -> Void

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
                LogDetailsCard(anxiety: anxiety, note: $note, setAnxiety: setAnxiety, noteGrew: noteGrew)
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
    let noteGrew: () -> Void

    private static let anxietyLabel = LocalizedStringResource(
        "log.details.anxiety",
        defaultValue: "How anxious, 0–10",
    )
    private static let anxietyNotSet = LocalizedStringResource("log.details.anxietyNotSet", defaultValue: "Not set")
    /// The note is shown again the next time this trigger sets the person off, so it asks for how it felt.
    private static let noteLabel = LocalizedStringResource("log.details.feeling", defaultValue: "How did it feel?")
    private static let notePlaceholder = LocalizedStringResource(
        "log.details.feelingPlaceholder",
        defaultValue: "In your own words, like \u{201C}chest tight, mind racing\u{201D}",
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
                // Grows with the note, up to five lines, then scrolls; Return starts a new line, as in Notes.
                TextField(text: $note, prompt: Text(Self.notePlaceholder), axis: .vertical) {
                    Text(Self.noteLabel)
                }
                .lineLimit(1 ... 5)
                // Only growing calls for a scroll: typing within a line, or the field emptying as the card closes,
                // leaves the view where the person put it.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { old, new in
                    if new > old {
                        noteGrew()
                    }
                }
                .font(.theme(.body))
                .foregroundStyle(.theme(.textPrimary))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(minHeight: 46)
                .id(LogDetails.noteFieldID)
                .background(.theme(.background), in: .rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.theme(.border)) }
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 20)
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
