import SwiftUI

/// "When did you notice?", once every step is answered. Optional: Save works without an answer.
///
/// Like `LogQuestion`, it takes values rather than the view model.
struct LogNoticed: View {
    let noticed: NoticeTiming?
    let notice: (NoticeTiming) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringResource("log.noticed.question", defaultValue: "When did you notice?"))
                    .font(.theme(.title3))
                    .foregroundStyle(.theme(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
                Text(LocalizedStringResource(
                    "log.noticed.hint",
                    defaultValue: "Any answer is fine. Noticing at all is the practice.",
                ))
                .font(.theme(.body))
                .foregroundStyle(.theme(.textSecondary))
            }
            FlowLayout(spacing: 8) {
                ForEach(NoticeTiming.allCases, id: \.self) { timing in
                    SelectableChip(timing.label, isSelected: timing == noticed) {
                        notice(timing)
                    }
                }
            }
        }
    }
}
