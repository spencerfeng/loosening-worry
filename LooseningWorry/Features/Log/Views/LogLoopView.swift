import SwiftData
import SwiftUI

/// Logs a loop in three one-tap steps: a summary card of the answers so far, then the current question.
struct LogLoopView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var savedOptions: [LoopOption]
    @State private var model = LogLoopViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LogSummaryCard(model: model)
                    if let step = model.currentStep {
                        LogQuestion(
                            step: step,
                            choices: OptionList.choices(for: step, saved: savedOptions),
                            selected: model.answer(for: step),
                            pick: model.pick,
                        )
                        .id(step)
                    }
                }
                .padding(20)
            }
            .background(.theme(.background))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    LogHeader(step: model.currentStep)
                }
            }
        }
    }
}

private struct LogHeader: View {
    let step: OptionKind?

    var body: some View {
        VStack(spacing: 2) {
            Text("Log a loop")
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textPrimary))
            Group {
                if let step {
                    Text("Step \(step.stepNumber) of \(OptionKind.allCases.count)")
                } else {
                    Text("All done")
                }
            }
            .font(.theme(.footnote))
            .foregroundStyle(.theme(.textSecondary))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// One row per step; tapping a row reopens that step.
private struct LogSummaryCard: View {
    let model: LogLoopViewModel

    var body: some View {
        VStack(spacing: 2) {
            ForEach(OptionKind.allCases, id: \.self) { step in
                LogSummaryRow(
                    step: step,
                    answer: model.answer(for: step),
                    isCurrent: model.currentStep == step,
                ) {
                    model.goTo(step)
                }
            }
        }
        .padding(6)
        .background(.theme(.surface), in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22).strokeBorder(.theme(.borderSubtle))
        }
    }
}

private struct LogSummaryRow: View {
    let step: OptionKind
    let answer: String?
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                marker
                VStack(alignment: .leading, spacing: 1) {
                    Text(step.logCopy.summaryLabel)
                        .textCase(.uppercase)
                        .font(.theme(.footnote))
                        .tracking(0.6)
                        .foregroundStyle(.theme(.textSecondary))
                    value
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 60)
            .background(isCurrent ? .theme(.accentTint) : .clear, in: .rect(cornerRadius: 16))
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private var marker: some View {
        ZStack {
            if answer != nil {
                Circle().fill(.theme(.accent))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.theme(.textOnAccent))
            } else if isCurrent {
                Circle().fill(.theme(.surface))
                Circle().strokeBorder(.theme(.accent), lineWidth: 2)
                Text(step.stepNumber, format: .number)
                    .font(.theme(.footnote))
                    .foregroundStyle(.theme(.accentText))
            } else {
                Circle().fill(.theme(.borderSubtle))
                Text(step.stepNumber, format: .number)
                    .font(.theme(.footnote))
                    .foregroundStyle(.theme(.textTertiary))
            }
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var value: some View {
        if let answer {
            Text(answer)
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textPrimary))
        } else {
            Group {
                if isCurrent {
                    Text("Choose below")
                } else {
                    Text(verbatim: "—")
                        .accessibilityLabel("Not answered yet")
                }
            }
            .font(.theme(.headline))
            .foregroundStyle(.theme(.textTertiary))
        }
    }
}

/// The current step's question and its options; tapping one answers the step.
private struct LogQuestion: View {
    let step: OptionKind
    let choices: [OptionChoice]
    let selected: String?
    let pick: (String) -> Void

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
            }
        }
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

#if DEBUG
    #Preview {
        LogLoopView()
            .modelContainer(AppModelContainer.preview)
    }
#endif
