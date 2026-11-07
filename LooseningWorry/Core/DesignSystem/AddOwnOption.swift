import SwiftUI

/// Opens and closes the field for the person's own option.
struct AddOwnChip: View {
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
struct AddOwnField: View {
    let step: OptionKind
    @Binding var draft: String
    let canAdd: Bool
    let add: () -> Void
    @FocusState private var isFocused: Bool

    private static let savedNote = LocalizedStringResource(
        "option.addOwn.savedNote",
        defaultValue: "It's saved to your list for next time.",
    )

    var body: some View {
        // The note sits one question-column gap below the field, as in the design.
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                TextField(text: $draft, prompt: Text(step.copy.addPlaceholder)) {
                    Text(step.copy.addLabel)
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
                    Text(LocalizedStringResource("option.addOwn.add", defaultValue: "Add"))
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
