import SwiftData
import SwiftUI

/// Logs a loop in three one-tap steps: a summary card of the answers so far, then the current question. Once the
/// loop is saved, Nice catch takes its place.
struct LogLoopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var savedOptions: [LoopOption]
    @State private var model = LogLoopViewModel(interpreter: FoundationModelsLoopInterpreter())
    /// The step whose options are being edited, when Edit options is open.
    @State private var editing: OptionKind?
    @State private var isShowingHelp = false
    /// Closes the logger and switches to Insights, from Nice catch's weekly count.
    let showInsights: () -> Void

    var body: some View {
        // Swapped in without a transition: a leaving view stays on screen until the animations inside it finish, and
        // the cheer's clap is still playing. Nice catch animates its own entrance.
        if let niceCatch = model.niceCatch {
            NiceCatchView(niceCatch: niceCatch, showInsights: showInsights) {
                dismiss()
            }
        } else {
            logger
        }
    }

    private var logger: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if model.showsHelp {
                            LogHelpRow { isShowingHelp = true }
                        }
                        if model.showsDescribe {
                            LogDescribeField(
                                text: $model.described,
                                canFillIn: model.canFillIn,
                                isFillingIn: model.isFillingIn,
                                couldntTell: model.couldntTell,
                            ) {
                                Task {
                                    await model.fillIn(saved: savedOptions)
                                }
                            }
                            LogOrDivider()
                                .padding(.vertical, -6)
                        }
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
                            let choices = model.choices(for: step, saved: savedOptions)
                            let visible = model.visibleChoices(choices, for: step)
                            LogQuestion(
                                step: step,
                                choices: visible.choices,
                                hasMore: visible.hasMore,
                                selectedID: model.answerID(in: choices, for: step),
                                isAddingOwn: model.isAddingOwn,
                                draft: $model.draft,
                                canAddOwn: model.canAddOwn,
                                suggestedOption: model.suggestedOption(for: step),
                            ) { choice in
                                withAnimation(stepAnimation) { model.pick(choice) }
                            } showMore: {
                                withAnimation(stepAnimation) { model.showAllChoices() }
                            } edit: {
                                editing = step
                            } toggleAddOwn: {
                                model.toggleAddOwn()
                            } addOwn: {
                                withAnimation(stepAnimation) {
                                    model.addOwn(existing: choices, save: saveOwnOption)
                                }
                            } addSuggested: {
                                withAnimation(stepAnimation) {
                                    model.addSuggestedOption(existing: choices, save: saveOwnOption)
                                }
                            }
                            .id(step)
                            .transition(questionTransition)
                        } else {
                            LogDetails(
                                isShowing: model.isShowingDetails,
                                anxiety: model.anxiety,
                                note: $model.note,
                            ) {
                                withAnimation(stepAnimation) { model.toggleDetails() }
                            } setAnxiety: { level in
                                model.setAnxiety(level)
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if model.currentStep == nil {
                    LogSaveBar(failed: model.saveFailed, canSave: model.canSave) {
                        let store = LoopStore(context: modelContext)
                        model.save { try store.add($0) } loopsThisWeek: { try store.loopsThisWeek() }
                    }
                }
            }
            .background(.theme(.background))
            .sheet(isPresented: $isShowingHelp) {
                HelpView()
            }
            .navigationDestination(item: $editing) { kind in
                EditOptionsView(kind: kind)
            }
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
            .onChange(of: model.couldntTell) { _, couldntTell in
                if couldntTell {
                    AccessibilityNotification.Announcement(String(localized: LogDescribeField.couldntTellMessage))
                        .post()
                }
            }
            .onChange(of: model.saveFailed) { _, failed in
                if failed {
                    AccessibilityNotification.Announcement(String(localized: LogSaveBar.failedMessage)).post()
                }
            }
            .onAppear {
                // If the count can't be read, the cheers start from the first set, which is harmless.
                model.loopsLogged = (try? modelContext.fetchCount(FetchDescriptor<Loop>())) ?? 0
                // Read once, so the order doesn't shift while the logger is open. Without it, the order is the
                // default one, which still works.
                let historyStart = OptionRanker.historyStart(before: .now)
                model.recentLoops = (try? LoopStore(context: modelContext).loops(since: historyStart)) ?? []
            }
            .sensoryFeedback(.selection, trigger: model.pickCount)
        }
    }

    /// Saves an option the person added, typed or suggested from their words, to their list.
    private func saveOwnOption(_ kind: OptionKind, _ label: String) throws -> OptionChoice {
        try OptionStore(context: modelContext).addOwn(label, kind: kind)
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

/// Encouragement for the step just answered. VoiceOver announces it when it changes, so the badge itself is not
/// read again.
private struct LogCheerBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let cheer: LogCheer
    /// Bumped on appear to play the clap; the badge is rebuilt for every cheer, so it plays once per pick.
    @State private var claps = 0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hands.clap.fill")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 18, height: 18)
                .keyframeAnimator(initialValue: ClapPose(), trigger: claps) { content, pose in
                    content
                        .rotationEffect(pose.rotation)
                        .scaleEffect(pose.scale)
                } keyframes: { _ in
                    // Two quick claps: it tips and swells, then settles, twice.
                    KeyframeTrack(\.rotation) {
                        CubicKeyframe(.degrees(-12), duration: 0.15)
                        CubicKeyframe(.zero, duration: 0.15)
                        CubicKeyframe(.degrees(-12), duration: 0.15)
                        CubicKeyframe(.zero, duration: 0.15)
                    }
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(1.25, duration: 0.15)
                        CubicKeyframe(1, duration: 0.15)
                        CubicKeyframe(1.25, duration: 0.15)
                        CubicKeyframe(1, duration: 0.15)
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
                claps += 1
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ClapPose {
    var rotation = Angle.zero
    var scale: CGFloat = 1
}

#if DEBUG
    #Preview {
        LogLoopView {}
            .modelContainer(AppModelContainer.preview)
    }
#endif
