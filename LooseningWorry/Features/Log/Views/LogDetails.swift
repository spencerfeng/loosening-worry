import SwiftUI

/// Once every step is answered: a link that opens the optional details, and the details themselves.
///
/// Like `LogQuestion`, it takes values rather than the view model, so it shows what it last showed while it leaves.
struct LogDetails: View {
    /// Scroll target for the details card, so the logger can keep the note being typed above the keyboard and the Save
    /// button, with the card's own padding showing below it.
    static let cardID = "LogDetails.card"

    let isShowing: Bool
    let anxiety: AnxietyControl
    @Binding var note: String
    /// Whether the note field has focus; the logger keeps it above the keyboard and the Save button while it does.
    var isNoteFocused: FocusState<Bool>.Binding
    let toggle: () -> Void
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
                LogDetailsCard(anxiety: anxiety, note: $note, isNoteFocused: isNoteFocused, noteGrew: noteGrew)
                    .transition(.opacity)
            }
        }
    }
}

/// How anxious the person felt and a note, both optional.
private struct LogDetailsCard: View {
    let anxiety: AnxietyControl
    @Binding var note: String
    var isNoteFocused: FocusState<Bool>.Binding
    let noteGrew: () -> Void

    private static let anxietyLabel = LocalizedStringResource(
        "log.details.anxiety",
        defaultValue: "How anxious were you?",
    )
    /// The note is shown again the next time this trigger sets the person off, so it asks for how it felt.
    private static let noteLabel = LocalizedStringResource("log.details.feeling", defaultValue: "How did it feel?")
    private static let notePlaceholder = LocalizedStringResource(
        "log.details.feelingPlaceholder",
        defaultValue: "In your own words, like \u{201C}chest tight, mind racing\u{201D}",
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Self.anxietyLabel)
                    .font(.theme(.footnote))
                    .fontWeight(.bold)
                    .foregroundStyle(.theme(.textSecondary))
                    // The row carries the same label for VoiceOver.
                    .accessibilityHidden(true)
                AnxietyRow(control: anxiety, label: Self.anxietyLabel)
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
                .focused(isNoteFocused)
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
                .background(.theme(.background), in: .rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.theme(.border)) }
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 20)
        .id(LogDetails.cardID)
    }
}

/// How anxious the person felt, if they said, and what they can do to it: the logger's level and its changes, kept
/// together as they pass down to the row.
struct AnxietyControl {
    let level: Int?
    /// Dragging along the row sets the level under the finger.
    let set: (Int) -> Void
    /// A tap picks a level, or takes back the one already picked.
    let pick: (Int) -> Void
    /// VoiceOver steps one level up or down.
    let step: (Int) -> Void
}

/// How anxious, 0 to 10, as a row of the numbers themselves, so the level and the scale read together. A tap picks a
/// number, or takes back the one already picked; dragging sideways along the row sets it as a slider would. The
/// numbers below the pick are tinted, so the row reads as a level rising to it.
private struct AnxietyRow: View {
    let control: AnxietyControl
    let label: LocalizedStringResource

    /// Whether this touch has moved sideways enough to be a drag rather than a tap. Cleared as each touch begins, so
    /// it can't carry over from one the scroll view took over and never ended.
    @State private var isDragging = false

    /// How far a touch moves before it's a drag, not a tap.
    private static let dragThreshold: CGFloat = 8
    private static let spacing: CGFloat = 3
    private static let levels = Array(LogLoopViewModel.anxietyRange)
    private static let notSet = LocalizedStringResource("log.details.anxietyNotSet", defaultValue: "Not set")
    private static let low = LocalizedStringResource("log.details.anxiety.low", defaultValue: "Not at all")
    private static let high = LocalizedStringResource("log.details.anxiety.high", defaultValue: "Extremely")

    /// Where a number sits relative to the pick, which sets its colors.
    private enum Cell {
        case picked, below, rest

        var fill: Theme.ColorRole {
            switch self {
            case .picked: .violetStrong
            case .below: .violetTint
            case .rest: .surfaceSunken
            }
        }

        /// On the picked cell, `background` rather than white: the violet is light in dark mode, and small white text
        /// on it falls short of 4.5:1 (ADR 0006).
        var ink: Theme.ColorRole {
            switch self {
            case .picked: .background
            case .below: .violetOnTint
            case .rest: .textSecondary
            }
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { proxy in
                HStack(spacing: Self.spacing) {
                    ForEach(Self.levels, id: \.self) { value in
                        let cell = cell(for: value)
                        Text(value, format: .number)
                            .font(.theme(.callout))
                            .monospacedDigit()
                            // "10" in a narrow cell at large text sizes shrinks rather than breaking.
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(.theme(cell.ink))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.theme(cell.fill), in: .rect(cornerRadius: 10))
                    }
                }
                .contentShape(.rect)
                // Alongside the scroll view's own drag, so scrolling up and down past the row still works.
                .simultaneousGesture(drag(width: proxy.size.width))
            }
            .frame(height: 44)
            HStack {
                Text(Self.low)
                Spacer()
                Text(Self.high)
            }
            .font(.theme(.caption))
            .foregroundStyle(.theme(.textTertiary))
        }
        .sensoryFeedback(.selection, trigger: control.level)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(control.level.map { Text($0, format: .number) } ?? Text(Self.notSet))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: control.step(1)
            case .decrement: control.step(-1)
            @unknown default: break
            }
        }
        // Activating the row would otherwise tap its middle and pick 5; swiping up and down sets it instead.
        .accessibilityAction {}
    }

    /// A tap picks or takes back a level; a drag that has once gone sideways sets the level under the finger, and
    /// never takes it back, even if it ends where it began.
    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if drag.translation == .zero {
                    isDragging = false
                }
                let sideways = abs(drag.translation.width) > max(Self.dragThreshold, abs(drag.translation.height))
                if sideways || isDragging {
                    isDragging = true
                    control.set(level(at: drag.location.x, width: width))
                }
            }
            .onEnded { drag in
                let moved = hypot(drag.translation.width, drag.translation.height)
                if !isDragging, moved < Self.dragThreshold {
                    control.pick(level(at: drag.location.x, width: width))
                }
                isDragging = false
            }
    }

    private func level(at x: CGFloat, width: CGFloat) -> Int {
        LogLoopViewModel.anxietyLevel(atX: x, rowWidth: width, spacing: Self.spacing)
    }

    private func cell(for value: Int) -> Cell {
        guard let level = control.level else { return .rest }
        if value == level {
            return .picked
        }
        return value < level ? .below : .rest
    }
}
