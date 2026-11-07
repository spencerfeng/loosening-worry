import SwiftUI

/// The "Edit" link beside a step's question, opening the Edit screen for its options. The visible word relies on the
/// question, so VoiceOver hears `label` instead, such as "Edit your triggers".
struct EditLink: View {
    let label: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(LocalizedStringResource("option.edit", defaultValue: "Edit"))
                .font(.theme(.callout))
                .foregroundStyle(.theme(.accentText))
                .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}
