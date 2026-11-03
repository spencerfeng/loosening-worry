import SwiftUI

/// A capsule to pick: an option in the logger, a word in the check-in. Filled with the accent once picked.
struct SelectableChip: View {
    let label: Text
    let isSelected: Bool
    let action: () -> Void

    /// A chip for the person's own words, shown as typed.
    init(verbatim label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.label = Text(verbatim: label)
        self.isSelected = isSelected
        self.action = action
    }

    init(_ label: LocalizedStringResource, isSelected: Bool, action: @escaping () -> Void) {
        self.label = Text(label)
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            label.chip(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension Text {
    func chip(isSelected: Bool) -> some View {
        font(.theme(.headline))
            .foregroundStyle(isSelected ? .theme(.textOnAccent) : .theme(.textPrimary))
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .background(isSelected ? .theme(.accent) : .theme(.surface), in: .capsule)
            .overlay {
                Capsule().strokeBorder(isSelected ? .theme(.accent) : .theme(.border))
            }
            .contentShape(.capsule)
    }
}
