import SwiftData
import SwiftUI

/// Logs a loop in three one-tap steps: a summary card of the answers so far, then the current question. Once the
/// loop is saved, Nice catch takes its place.
struct LogLoopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var savedOptions: [LoopOption]
    @State private var model = LogLoopViewModel()
    /// The step whose options are being edited, when Edit options is open.
    @State private var editing: OptionKind?
    /// The tool the person is meeting the urge with, after "Nothing yet".
    @State private var meetingTool: QuickTool?
    /// What the person wrote the last time this trigger set them off, read when they choose "Nothing yet".
    @State private var lastNoted: Loop?
    /// Set when a tool run from "Nothing yet" saved its loop, so the logger closes with the tool.
    @State private var savedByTool = false

    var body: some View {
        // Swapped in without a transition: a leaving view stays on screen until the animations inside it finish, such
        // as the summary card's pop. Nice catch animates its own entrance.
        if let niceCatch = model.niceCatch {
            NiceCatchView(niceCatch: niceCatch) {
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
                        LogSummaryCard(model: model) { step in
                            withAnimation(stepAnimation) { model.goTo(step) }
                        }
                        if let label = model.ownDraft.unsavedLabel {
                            Text(Self.unsavedNote(label))
                                .font(.theme(.caption))
                                .foregroundStyle(.theme(.textSecondary))
                        }
                        if model.isMeeting {
                            LogMeetIt(lastNoted: lastNoted) { tool in
                                meetingTool = tool
                            } back: {
                                withAnimation(stepAnimation) { model.stopMeeting() }
                            }
                            .transition(questionTransition)
                        } else if let step = model.currentStep {
                            let choices = model.choices(for: step, saved: savedOptions)
                            let visible = model.visibleChoices(choices, for: step)
                            LogQuestion(
                                step: step,
                                choices: visible.choices,
                                hasMore: visible.hasMore,
                                selectedID: model.answerID(in: choices, for: step),
                                isAddingOwn: model.ownDraft.isOpen,
                                draft: $model.ownDraft.text,
                                canAddOwn: model.ownDraft.canAdd,
                                meetIt: step == .behavior ? { meetIt() } : nil,
                            ) { choice in
                                withAnimation(stepAnimation) { model.pick(choice) }
                            } showMore: {
                                withAnimation(stepAnimation) { model.showAllChoices() }
                            } edit: {
                                editing = step
                            } toggleAddOwn: {
                                model.ownDraft.toggle()
                            } addOwn: {
                                withAnimation(stepAnimation) {
                                    model.addOwn(existing: choices, save: saveOwnOption)
                                }
                            }
                            .id(step)
                            .transition(questionTransition)
                        } else {
                            LogNoticed(noticed: model.noticed) { timing in
                                withAnimation(stepAnimation) { model.notice(timing) }
                            }
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
                .keepsAboveKeyboard(
                    LogQuestion.addOwnFieldID,
                    isShowing: model.ownDraft.isOpen,
                    in: proxy,
                    animation: stepAnimation,
                )
            }
            // Stays under the header while the questions scroll.
            .safeAreaInset(edge: .top, spacing: 0) {
                StepProgressBar(steps: OptionKind.loopSteps.map { model.progress(for: $0) })
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .background(.theme(.background))
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if model.currentStep == nil {
                    PrimaryActionBar(
                        title: LocalizedStringResource("log.save", defaultValue: "Save loop"),
                        failure: model.saveFailed ? Self.saveFailedMessage : nil,
                        isEnabled: model.canSave,
                    ) {
                        let store = LoopStore(context: modelContext)
                        model.save { try store.add($0) } history: { try store.loops(like: $0) }
                    }
                }
            }
            .background(.theme(.background))
            .navigationDestination(item: $editing) { kind in
                EditOptionsView(kind: kind)
            }
            // Closing the tool comes back here, trigger kept; finishing it, with its loop saved, closes the logger too.
            .fullScreenCover(item: $meetingTool, onDismiss: closeIfSavedByTool) { tool in
                ToolRunView(
                    tool: tool,
                    sessions: SessionStore(context: modelContext),
                    meeting: model.answer(for: .trigger),
                ) { savedLoop in
                    savedByTool = savedLoop != nil
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    FlowHeader(
                        title: "Log a loop",
                        detail: model.currentStep.map { "Step \($0.stepNumber) of \(OptionKind.loopSteps.count)" }
                            ?? "All done",
                    )
                }
            }
            .onChange(of: model.pickCount) {
                if let label = model.ownDraft.unsavedLabel {
                    AccessibilityNotification.Announcement(String(localized: Self.unsavedNote(label))).post()
                }
            }
            .onChange(of: model.saveFailed) { _, failed in
                if failed {
                    AccessibilityNotification.Announcement(String(localized: Self.saveFailedMessage)).post()
                }
            }
            .onAppear {
                // Read once, so the order doesn't shift while the logger is open. Without it, the order is the
                // default one, which still works.
                let historyStart = OptionRanker.historyStart(before: .now)
                model.recentLoops = (try? LoopStore(context: modelContext).loops(since: historyStart)) ?? []
            }
            .sensoryFeedback(.selection, trigger: model.pickCount)
        }
    }

    private func meetIt() {
        if let trigger = model.answer(for: .trigger) {
            // Without it, the screen just has no "Last time"; meeting the urge still works.
            lastNoted = try? LoopStore(context: modelContext).lastNoted(forTrigger: trigger.id)
        }
        withAnimation(stepAnimation) { model.meetIt() }
    }

    private func closeIfSavedByTool() {
        if savedByTool {
            dismiss()
        }
    }

    static let saveFailedMessage = LocalizedStringResource(
        "log.save.failed",
        defaultValue: "Couldn't save this loop. Please try again.",
    )

    /// Saves an option the person added to their list.
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

    /// Under Reduce Motion, changes fade instead of moving.
    private var stepAnimation: Animation {
        .easeOut(duration: reduceMotion ? 0.2 : 0.28)
    }

    /// The next question slides in from the right; the one it replaces leaves at once, so the two never overlap.
    private var questionTransition: AnyTransition {
        .asymmetric(
            insertion: reduceMotion ? .opacity : .offset(x: 28).combined(with: .opacity),
            removal: .identity,
        )
    }
}

#if DEBUG
    #Preview {
        LogLoopView()
            .modelContainer(AppModelContainer.preview)
    }
#endif
