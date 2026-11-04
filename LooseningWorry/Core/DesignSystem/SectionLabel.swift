import SwiftUI

/// A small uppercase heading over a group, such as Nice catch's "Turn toward what's here" or a Settings section.
struct SectionLabel: View {
    let text: LocalizedStringResource

    init(_ text: LocalizedStringResource) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .font(.theme(.footnote))
            .fontWeight(.bold)
            .tracking(0.6)
            .foregroundStyle(.theme(.textTertiary))
            .accessibilityAddTraits(.isHeader)
    }
}
