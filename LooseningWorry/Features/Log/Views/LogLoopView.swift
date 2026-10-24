import SwiftData
import SwiftUI

/// Logs a loop in three one-tap steps: a summary card of the answers so far, then the current question.
struct LogLoopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var savedOptions: [LoopOption]
    @State private var model = LogLoopViewModel()

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        LogSummaryCard(model: model) { step in
                            withAnimation(stepAnimation) { model.goTo(step) }
                        }
                        if let cheer = model.cheer {
                            LogCheerBadge(cheer: cheer)
                                // A new badge for every pick, so it replays even when a step is answered again.
                                .id(model.pickCount)
                                // Sits closer to its neighbors than the stack's spacing.
                                .padding(.top, -8)
                                .padding(.bottom, -6)
                                .transition(cheerTransition)
                        }
                        if let label = model.unsavedOption {
                            Text(Self.unsavedNote(label))
                                .font(.theme(.caption))
                                .foregroundStyle(.theme(.textSecondary))
                        }
                        if let step = model.currentStep {
                            let choices = OptionList.choices(for: step, saved: savedOptions)
                            LogQuestion(
                                step: step,
                                choices: choices,
                                selected: model.answer(for: step),
                                isAddingOwn: model.isAddingOwn,
                                draft: $model.draft,
                                canAddOwn: model.canAddOwn,
                            ) { label in
                                withAnimation(stepAnimation) { model.pick(label) }
                            } toggleAddOwn: {
                                model.toggleAddOwn()
                            } addOwn: {
                                withAnimation(stepAnimation) {
                                    model.addOwn(existing: choices) { kind, label in
                                        try OptionStore(context: modelContext).addOwn(label, kind: kind)
                                    }
                                }
                            }
                            .id(step)
                            .transition(questionTransition)
                        }
                    }
                    .padding(20)
                }
                // The keyboard covers the bottom of the sheet, so keep the add-your-own field and its Add button above
                // it: when the field opens, and again once the keyboard has shrunk the visible area.
                .onChange(of: model.isAddingOwn) { revealAddOwnField(with: proxy) }
                .onGeometryChange(for: CGFloat.self) { $0.size.height - $0.safeAreaInsets.bottom } action: { _ in
                    revealAddOwnField(with: proxy)
                }
            }
            // Stays under the header while the questions scroll.
            .safeAreaInset(edge: .top, spacing: 0) {
                LogProgressBar(model: model)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .background(.theme(.background))
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
            .onChange(of: model.pickCount) {
                if let cheer = model.cheer {
                    // One announcement, so the note about an unsaved option isn't cut off by the cheer.
                    var announcement = String(localized: cheer.message)
                    if let label = model.unsavedOption {
                        announcement += " " + String(localized: Self.unsavedNote(label))
                    }
                    AccessibilityNotification.Announcement(announcement).post()
                }
            }
            .onAppear {
                // If the count can't be read, the cheers start from the first set, which is harmless.
                model.loopsLogged = (try? modelContext.fetchCount(FetchDescriptor<Loop>())) ?? 0
            }
            .sensoryFeedback(.selection, trigger: model.pickCount)
        }
    }

    /// Shown when an added option was picked but couldn't be saved to the person's list.
    private static func unsavedNote(_ label: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "log.addOwn.notSaved",
            defaultValue: "Couldn't save \"\(label)\" to your list, but it's in this loop.",
        )
    }

    private func revealAddOwnField(with proxy: ScrollViewProxy) {
        guard model.isAddingOwn else { return }
        withAnimation(stepAnimation) {
            proxy.scrollTo(LogQuestion.addOwnFieldID, anchor: .bottom)
        }
    }

    /// Under Reduce Motion, changes fade instead of moving.
    private var stepAnimation: Animation {
        .easeOut(duration: reduceMotion ? 0.2 : 0.28)
    }

    /// The cheer rises a little and grows into place as it fades in.
    private var cheerTransition: AnyTransition {
        let appear: AnyTransition = reduceMotion
            ? .opacity
            : .offset(y: 6).combined(with: .scale(scale: 0.96)).combined(with: .opacity)
        // The old cheer leaves at once, so the two never take up space together and push the question down.
        return .asymmetric(
            insertion: appear.animation(.easeOut(duration: reduceMotion ? 0.2 : 0.36)),
            removal: .identity,
        )
    }

    /// The next question slides in from the right; the one it replaces leaves at once, so the two never overlap.
    private var questionTransition: AnyTransition {
        .asymmetric(
            insertion: reduceMotion ? .opacity : .offset(x: 28).combined(with: .opacity),
            removal: .identity,
        )
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

/// One segment per step: full once answered, partly filled while current. The header already says which step, so
/// VoiceOver skips it.
private struct LogProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let model: LogLoopViewModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(OptionKind.allCases, id: \.self) { step in
                Capsule()
                    .fill(.theme(.border))
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.theme(.accentSoft), .theme(.accent)],
                                        startPoint: .leading,
                                        endPoint: .trailing,
                                    )
                                )
                                .frame(width: proxy.size.width * fill(for: model.progress(for: step)))
                        }
                    }
                    .frame(height: 6)
            }
        }
        // A width change is movement even when slow, so under Reduce Motion the segments jump instead.
        .transaction { transaction in
            if transaction.animation != nil {
                transaction.animation = reduceMotion ? nil : .easeOut(duration: 0.3)
            }
        }
        .accessibilityHidden(true)
    }

    private func fill(for progress: StepProgress) -> CGFloat {
        switch progress {
        case .answered, .reopened: 1
        case .current: 0.35
        case .upcoming: 0
        }
    }
}

/// One row per step; tapping a row reopens that step.
private struct LogSummaryCard: View {
    let model: LogLoopViewModel
    let reopen: (OptionKind) -> Void

    var body: some View {
        VStack(spacing: 2) {
            ForEach(OptionKind.allCases, id: \.self) { step in
                LogSummaryRow(
                    step: step,
                    answer: model.answer(for: step),
                    progress: model.progress(for: step),
                    popTrigger: model.cheer?.step == step ? model.pickCount : nil,
                ) {
                    reopen(step)
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
    let progress: StepProgress
    /// The latest pick when it answered this step, so re-answering the step pops its tick again.
    let popTrigger: Int?
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
                if progress.isCurrent {
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

/// Encouragement for the step just answered. VoiceOver announces it when it changes, so the badge itself is not
/// read again.
private struct LogCheerBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let cheer: LogCheer
    /// Bumped on appear to play the sparkle; the badge is rebuilt for every cheer, so it plays once per pick.
    @State private var sparkles = 0

    var body: some View {
        HStack(spacing: 8) {
            SparkleShape()
                .frame(width: 18, height: 18)
                .keyframeAnimator(initialValue: SparklePose(), trigger: sparkles) { content, pose in
                    content
                        .rotationEffect(pose.rotation)
                        .scaleEffect(pose.scale)
                } keyframes: { _ in
                    // Tilts and grows, then settles, twice.
                    KeyframeTrack(\.rotation) {
                        CubicKeyframe(.degrees(20), duration: 0.6)
                        CubicKeyframe(.zero, duration: 0.6)
                        CubicKeyframe(.degrees(20), duration: 0.6)
                        CubicKeyframe(.zero, duration: 0.6)
                    }
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(1.2, duration: 0.6)
                        CubicKeyframe(1, duration: 0.6)
                        CubicKeyframe(1.2, duration: 0.6)
                        CubicKeyframe(1, duration: 0.6)
                    }
                }
            Text(cheer.message)
        }
        .font(.theme(.subheadline))
        .foregroundStyle(.theme(.accentPressed))
        .padding(.vertical, 8)
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .background(.theme(.surface), in: .capsule)
        .overlay { Capsule().strokeBorder(.theme(.accentTint)) }
        .shadow(color: .theme(.accentShadow).opacity(0.14), radius: 7, y: 4)
        .onAppear {
            if !reduceMotion {
                sparkles += 1
            }
        }
        .accessibilityHidden(true)
    }
}

/// The design's sparkle: a four-point star with a small dot below right, drawn on a 24-point grid.
private struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let unit = min(rect.width, rect.height) / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * unit, y: rect.minY + y * unit)
        }
        var path = Path()
        path.addLines([
            point(12, 2), point(14.2, 8.3), point(20, 10), point(14.2, 11.7),
            point(12, 18), point(9.8, 11.7), point(4, 10), point(9.8, 8.3),
        ])
        path.closeSubpath()
        path.addEllipse(in: CGRect(origin: point(17, 17), size: CGSize(width: 4 * unit, height: 4 * unit)))
        return path
    }
}

private struct SparklePose {
    var rotation = Angle.zero
    var scale: CGFloat = 1
}

#if DEBUG
    #Preview {
        LogLoopView()
            .modelContainer(AppModelContainer.preview)
    }
#endif
