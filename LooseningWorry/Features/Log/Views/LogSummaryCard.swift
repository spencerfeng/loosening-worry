import SwiftUI

/// One row per step; tapping a row reopens that step.
struct LogSummaryCard: View {
    let model: LogLoopViewModel
    let reopen: (OptionKind) -> Void

    var body: some View {
        VStack(spacing: 2) {
            ForEach(OptionKind.allCases, id: \.self) { step in
                LogSummaryRow(
                    step: step,
                    isMeeting: step == .behavior && model.isMeeting,
                    // While the person picks a tool, step 2 has no answer yet, even one from before they reopened it.
                    answer: step == .behavior && model.isMeeting ? nil : model.answer(for: step)?.label,
                    progress: model.progress(for: step),
                    popTrigger: model.popTrigger(for: step),
                ) {
                    reopen(step)
                }
            }
        }
        .padding(6)
        .cardSurface(cornerRadius: 22)
    }
}

private struct LogSummaryRow: View {
    let step: OptionKind
    /// Step 2 while the person picks a tool to meet the urge with, rather than a habit that already ran.
    let isMeeting: Bool
    let answer: String?
    let progress: StepProgress
    /// The latest pick when it answered this step, so re-answering the step pops its tick again.
    let popTrigger: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                marker
                VStack(alignment: .leading, spacing: 1) {
                    Text(isMeeting
                        ? LocalizedStringResource("log.meetIt.summaryLabel", defaultValue: "What you'll do")
                        : step.logCopy.summaryLabel)
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
            .background(progress.isCurrent ? .theme(.accentWash) : .clear, in: .rect(cornerRadius: 16))
            .overlay {
                if progress.isCurrent {
                    RoundedRectangle(cornerRadius: 16).strokeBorder(.theme(.accentBorder), lineWidth: 1.5)
                }
            }
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(progress.isCurrent ? .isSelected : [])
    }

    private var marker: some View {
        ZStack {
            switch progress {
            case .answered, .reopened:
                TickDot(popTrigger: popTrigger)
            case .current:
                numberDot(fill: .theme(.surface), ink: .theme(.accentText))
                    .overlay { Circle().strokeBorder(.theme(.accent), lineWidth: 2) }
            case .upcoming:
                numberDot(fill: .theme(.borderSubtle), ink: .theme(.textTertiary))
            }
        }
        .frame(width: 26, height: 26)
        // Colors cross-fade; that is not motion, so it stays under Reduce Motion.
        .animation(.easeOut(duration: 0.2), value: progress)
        .accessibilityHidden(true)
    }

    private func numberDot(fill: Color, ink: Color) -> some View {
        Text(step.stepNumber, format: .number)
            .font(.theme(.footnote))
            .foregroundStyle(ink)
            .frame(width: 26, height: 26)
            .background(fill, in: .circle)
    }

    @ViewBuilder private var value: some View {
        if let answer {
            Text(answer)
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textPrimary))
        } else {
            Group {
                if isMeeting {
                    Text(LocalizedStringResource("log.meetIt.pickTool", defaultValue: "Pick a tool below"))
                } else if progress.isCurrent {
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

/// The answered step's tick. It pops in, growing past full size and settling back, each time the step is answered.
private struct TickDot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let popTrigger: Int?
    @State private var pops = 0
    /// A new tick grows in from small; a tick that is already showing just bulges, so it never jumps.
    @State private var popStart: CGFloat = 0.4

    var body: some View {
        ZStack {
            Circle().fill(.theme(.accent))
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(.theme(.textOnAccent))
        }
        .shadow(color: .theme(.accentShadow).opacity(0.35), radius: 3, y: 2)
        .keyframeAnimator(initialValue: CGFloat(1), trigger: pops) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                MoveKeyframe(popStart)
                CubicKeyframe(1.15, duration: 0.224)
                CubicKeyframe(1, duration: 0.096)
            }
        }
        .onAppear { pop(from: 0.4) }
        .onChange(of: popTrigger) { _, trigger in
            if trigger != nil {
                pop(from: 1)
            }
        }
    }

    private func pop(from scale: CGFloat) {
        if !reduceMotion {
            popStart = scale
            pops += 1
        }
    }
}
