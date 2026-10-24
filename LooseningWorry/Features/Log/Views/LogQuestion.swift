import SwiftUI

/// The current step's question and its options; tapping one answers the step.
///
/// It takes values, not the view model, so a question that is leaving shows what it last showed. If it watched the
/// model, the answer just picked would animate in the leaving question, and SwiftUI keeps a leaving view on screen
/// until its animations finish, so its options would sit over the next question's.
struct LogQuestion: View {
    /// Scroll target for the add-your-own field, so the logger can keep it above the keyboard.
    static let addOwnFieldID = "LogQuestion.addOwnField"

    let step: OptionKind
    let choices: [OptionChoice]
    /// The step's answer, if it has one.
    let selected: String?
    let isAddingOwn: Bool
    @Binding var draft: String
    let canAddOwn: Bool
    let pick: (String) -> Void
    let toggleAddOwn: () -> Void
    let addOwn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(step.logCopy.question)
                    .font(.theme(.title))
                    .foregroundStyle(.theme(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
                Text(step.logCopy.hint)
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textSecondary))
            }
            FlowLayout(spacing: 8) {
                ForEach(choices, id: \.label) { choice in
                    OptionChip(label: choice.label, isSelected: choice.label == selected) {
                        pick(choice.label)
                    }
                }
                AddOwnChip(isOpen: isAddingOwn, action: toggleAddOwn)
            }
            if isAddingOwn {
                AddOwnField(step: step, draft: $draft, canAdd: canAddOwn, add: addOwn)
                    .id(Self.addOwnFieldID)
            }
        }
    }
}

/// Opens and closes the field for the person's own option.
private struct AddOwnChip: View {
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // The plus is drawn, not written, so VoiceOver reads just "Add your own" and translators never see it.
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .fontWeight(.bold)
                    .accessibilityHidden(true)
                Text("Add your own")
            }
            .font(.theme(.headline))
            .foregroundStyle(.theme(.accentText))
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .background(isOpen ? .theme(.accentWash) : .clear, in: .capsule)
            .overlay {
                Capsule().strokeBorder(
                    isOpen ? .theme(.accent) : .theme(.accentOutline),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]),
                )
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOpen ? Text("Open") : Text("Closed"))
    }
}

/// Where the person types their own option. It takes focus when it opens, and Return adds the text like the
/// Add button does.
private struct AddOwnField: View {
    let step: OptionKind
    @Binding var draft: String
    let canAdd: Bool
    let add: () -> Void
    @FocusState private var isFocused: Bool

    private static let savedNote = LocalizedStringResource(
        "log.addOwn.savedNote",
        defaultValue: "It's saved to your list for next time.",
    )

    var body: some View {
        // The note sits one question-column gap below the field, as in the design.
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                TextField(text: $draft, prompt: Text(step.logCopy.addPlaceholder)) {
                    Text(step.logCopy.addLabel)
                }
                .font(.theme(.body))
                .foregroundStyle(.theme(.textPrimary))
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(add)
                .accessibilityHint(Text(Self.savedNote))
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(.theme(.surface), in: .capsule)
                .overlay { Capsule().strokeBorder(.theme(.accent), lineWidth: 2) }

                Button(action: add) {
                    Text(LocalizedStringResource("log.addOwn.add", defaultValue: "Add"))
                        .font(.theme(.headline))
                        .foregroundStyle(.theme(.textOnAccent))
                        .padding(.horizontal, 18)
                        .frame(minHeight: 48)
                        .background(.theme(.accent), in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
                .opacity(canAdd ? 1 : 0.5)
            }
            Text(Self.savedNote)
                .font(.theme(.caption))
                .foregroundStyle(.theme(.textTertiary))
                // VoiceOver hears it as the field's hint instead.
                .accessibilityHidden(true)
        }
        .onAppear { isFocused = true }
    }
}

private struct OptionChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.theme(.headline))
                .foregroundStyle(isSelected ? .theme(.textOnAccent) : .theme(.textPrimary))
                .padding(.horizontal, 18)
                .frame(minHeight: 48)
                .background(isSelected ? .theme(.accent) : .theme(.surface), in: .capsule)
                .overlay {
                    Capsule().strokeBorder(isSelected ? .theme(.accent) : .theme(.border))
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
