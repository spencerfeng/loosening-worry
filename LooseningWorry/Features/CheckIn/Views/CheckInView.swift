import SwiftData
import SwiftUI

/// A check-in in three steps, how it feels overall, the words for it and what's having the biggest impact, then a
/// finish screen with something to try.
struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = CheckInViewModel()
    /// Whether the Edit screen for contexts is showing, opened from step 3.
    @State private var isEditingContexts = false
    /// Closes the check-in and opens the logger, from the finish screen's link.
    let logLoop: () -> Void

    var body: some View {
        // Swapped in without a transition, like Nice catch after the logger.
        if let suggestion = model.suggestion {
            CheckInFinishedView(model: model, suggestion: suggestion, logLoop: logLoop) { dismiss() }
        } else {
            steps
        }
    }

    private var steps: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    Group {
                        switch model.step {
                        case .contexts:
                            ContextsQuestion(model: model, save: saveOwnContext) { isEditingContexts = true }
                                .transition(stepTransition)
                        case .feelings:
                            FeelingsQuestion(model: model)
                                .transition(stepTransition)
                        default:
                            PleasantnessQuestion(model: model)
                                .transition(stepTransition)
                        }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
                .keepsAboveKeyboard(
                    ContextsQuestion.addOwnFieldID,
                    isShowing: model.ownDraft.isOpen,
                    in: proxy,
                    animation: stepAnimation,
                )
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                StepProgressBar(steps: stepProgress)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .background(.theme(.background))
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PrimaryActionBar(
                    title: model.step == .contexts
                        ? LocalizedStringResource("checkIn.done", defaultValue: "Done")
                        : LocalizedStringResource("checkIn.next", defaultValue: "Next"),
                    failure: model.saveFailed ? Self.saveFailedMessage : nil,
                    isEnabled: model.pleasantness != nil,
                    action: goOn,
                )
            }
            .background(.theme(.background))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if model.step != .pleasantness {
                        Button {
                            withAnimation(stepAnimation) { model.back() }
                        } label: {
                            Label {
                                Text(LocalizedStringResource("checkIn.back", defaultValue: "Back"))
                            } icon: {
                                Image(systemName: "chevron.backward")
                            }
                        }
                    } else {
                        Button(role: .close) { dismiss() }
                    }
                }
                ToolbarItem(placement: .principal) {
                    FlowHeader(
                        title: LocalizedStringResource("checkIn.title", defaultValue: "Check-in"),
                        detail: "Step \(stepNumber) of \(stepProgress.count)",
                    )
                }
            }
            .sensoryFeedback(.selection, trigger: model.pleasantness)
            .sensoryFeedback(.selection, trigger: model.feelings)
            .sensoryFeedback(.selection, trigger: model.contexts.map(\.id))
            .navigationDestination(isPresented: $isEditingContexts) {
                // A context added there comes back picked, like one added on the step.
                EditOptionsView(kind: .context) { model.pick($0) }
            }
        }
    }

    /// Where each of the three steps stands, for the progress bar and the header.
    private var stepProgress: [StepProgress] {
        switch model.step {
        case .feelings: [.answered, .current, .upcoming]
        case .contexts: [.answered, .answered, .current]
        default: [.current, .upcoming, .upcoming]
        }
    }

    /// The step being asked, counting from 1.
    private var stepNumber: Int {
        (stepProgress.firstIndex(of: .current) ?? 0) + 1
    }

    /// Next on steps 1 and 2; on step 3, Done saves. Every failed try is announced, not just the first.
    private func goOn() {
        guard model.step == .contexts else {
            withAnimation(stepAnimation) { model.next() }
            return
        }
        let store = CheckInStore(context: modelContext)
        model.finish(addingDraftWith: saveOwnContext) { try store.add($0) }
        if model.saveFailed {
            AccessibilityNotification.Announcement(String(localized: Self.saveFailedMessage)).post()
        }
    }

    /// Saves a context the person added to their list.
    private func saveOwnContext(_ label: String) throws -> OptionChoice {
        try OptionStore(context: modelContext).addOwn(label, kind: .context)
    }

    private static let saveFailedMessage = LocalizedStringResource(
        "checkIn.save.failed",
        defaultValue: "Couldn't save this check-in. Please try again.",
    )

    private var stepAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.28)
    }

    /// A step comes in from the side it lies on: a later one from the trailing edge, an earlier one, after Back,
    /// from the leading edge. The step it replaces fades.
    private var stepTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: model.direction == .back ? .leading : .trailing).combined(with: .opacity),
            removal: .opacity,
        )
    }
}

/// A step's question and hint, with an Edit link beside the question when the step's options can be edited. VoiceOver
/// moves to the question when the step appears.
private struct QuestionHeading: View {
    @AccessibilityFocusState private var isFocused: Bool

    let question: LocalizedStringResource
    let hint: LocalizedStringResource
    /// Opens the step's Edit screen, with what VoiceOver calls the link.
    var edit: (label: LocalizedStringResource, action: () -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(question)
                    .font(.theme(.title))
                    .foregroundStyle(.theme(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isFocused)
                if let edit {
                    Spacer(minLength: 0)
                    EditLink(label: edit.label, action: edit.action)
                }
            }
            Text(hint)
                .font(.theme(.body))
                .foregroundStyle(.theme(.textSecondary))
        }
        .onAppear { isFocused = true }
    }
}

/// Step 1: the seven steps from very unpleasant to very pleasant, one to choose.
private struct PleasantnessQuestion: View {
    let model: CheckInViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            QuestionHeading(
                question: LocalizedStringResource(
                    "checkIn.pleasantness.question",
                    defaultValue: "How are you feeling right now?",
                ),
                hint: LocalizedStringResource(
                    "checkIn.pleasantness.hint",
                    defaultValue: "Overall, from unpleasant to pleasant.",
                ),
            )
            VStack(spacing: 2) {
                ForEach(Pleasantness.allCases, id: \.self) { pleasantness in
                    PleasantnessRow(pleasantness: pleasantness, isChosen: model.pleasantness == pleasantness) {
                        model.choose(pleasantness)
                    }
                }
            }
            .padding(6)
            .cardSurface(cornerRadius: 22)
        }
    }
}

private struct PleasantnessRow: View {
    let pleasantness: Pleasantness
    let isChosen: Bool
    let choose: () -> Void

    var body: some View {
        Button(action: choose) {
            HStack(spacing: 8) {
                PleasantnessMark(pleasantness: pleasantness)
                    .frame(width: 40)
                Text(pleasantness.label)
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textPrimary))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.theme(.textOnAccent))
                    .frame(width: 24, height: 24)
                    .background(.theme(.accent), in: .circle)
                    .opacity(isChosen ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .frame(minHeight: 52)
            // The current row in a list (ADR 0004).
            .background(isChosen ? .theme(.accentWash) : .clear, in: .rect(cornerRadius: 16))
            .overlay {
                if isChosen {
                    RoundedRectangle(cornerRadius: 16).strokeBorder(.theme(.accentBorder), lineWidth: 1.5)
                }
            }
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}

/// A dot that grows toward each end of the scale: violet for unpleasant, amber for pleasant, so the two sides
/// differ in lightness as well as hue.
private struct PleasantnessMark: View {
    let pleasantness: Pleasantness

    var body: some View {
        Circle()
            .fill(.theme(color))
            .opacity(opacity)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var size: CGFloat {
        switch pleasantness {
        case .veryUnpleasant, .veryPleasant: 22
        case .unpleasant, .pleasant: 18
        case .slightlyUnpleasant, .slightlyPleasant: 14
        case .neutral: 10
        }
    }

    private var color: Theme.ColorRole {
        switch pleasantness.side {
        case .unpleasant: .violetStrong
        case .neutral: .textTertiary
        case .pleasant: .amberStrong
        }
    }

    private var opacity: Double {
        switch pleasantness {
        case .slightlyUnpleasant, .slightlyPleasant: 0.55
        case .unpleasant, .pleasant: 0.8
        case .veryUnpleasant, .neutral, .veryPleasant: 1
        }
    }
}

/// Step 2: the words, those that fit step 1 first and the rest behind More, any number to pick.
private struct FeelingsQuestion: View {
    let model: CheckInViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let grouped = model.groupedFeelings
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                if let pleasantness = model.pleasantness {
                    HStack(spacing: 8) {
                        PleasantnessMark(pleasantness: pleasantness)
                            .scaleEffect(0.65)
                            .frame(width: 14, height: 14)
                        Text(pleasantness.label)
                            .font(.theme(.footnote))
                            .fontWeight(.bold)
                            .foregroundStyle(.theme(.textSecondary))
                    }
                    .padding(.vertical, 6)
                    .padding(.leading, 8)
                    .padding(.trailing, 12)
                    .background(.theme(.surfaceSunken), in: .capsule)
                }
                QuestionHeading(
                    question: LocalizedStringResource(
                        "checkIn.feelings.question",
                        defaultValue: "What best describes this feeling?",
                    ),
                    hint: LocalizedStringResource(
                        "checkIn.feelings.hint",
                        defaultValue: "Optional. Tap Next if no word fits.",
                    ),
                )
            }
            if model.showsMoreFeelings {
                chips(grouped.first)
                SectionLabel(LocalizedStringResource("checkIn.feelings.more", defaultValue: "More"))
                    .padding(.top, 6)
                chips(grouped.more)
            } else {
                chips(grouped.first) {
                    MoreChip {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) { model.showMoreFeelings() }
                    }
                }
            }
        }
    }

    private func chips(_ feelings: [Feeling], @ViewBuilder after: () -> some View = { EmptyView() }) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(feelings, id: \.self) { feeling in
                SelectableChip(feeling.label, isSelected: model.feelings.contains(feeling)) {
                    model.toggle(feeling)
                }
            }
            after()
        }
    }
}

/// Step 3: what's having the biggest impact, any number to pick, with the person's own contexts added in place or on
/// the Edit screen.
private struct ContextsQuestion: View {
    /// Scroll target for the add-your-own field, so the check-in can keep it above the keyboard.
    static let addOwnFieldID = "ContextsQuestion.addOwnField"

    @Bindable var model: CheckInViewModel
    /// Saves a context the person added to their list.
    let save: (String) throws -> OptionChoice
    let edit: () -> Void
    @Query private var savedOptions: [LoopOption]

    var body: some View {
        let choices = OptionList.choices(for: .context, saved: savedOptions)
        let copy = OptionKind.context.copy
        VStack(alignment: .leading, spacing: 16) {
            QuestionHeading(question: copy.question, hint: copy.hint, edit: (copy.editLabel, edit))
            FlowLayout(spacing: 8) {
                ForEach(model.contextChips, id: \.id) { choice in
                    SelectableChip(verbatim: choice.label, isSelected: model.isPicked(choice)) {
                        model.toggle(choice)
                    }
                }
                AddOwnChip(isOpen: model.ownDraft.isOpen) { model.ownDraft.toggle() }
            }
            if model.ownDraft.isOpen {
                AddOwnField(step: .context, draft: $model.ownDraft.text, canAdd: model.ownDraft.canAdd) {
                    model.addOwn(save: save)
                }
                .id(Self.addOwnFieldID)
            }
            if let label = model.ownDraft.unsavedLabel {
                Text(Self.unsavedNote(label))
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textSecondary))
            }
        }
        .onChange(of: choices.map(\.id), initial: true) { model.showContextChoices(choices) }
        .onChange(of: model.ownDraft.unsavedLabel) { _, label in
            if let label {
                AccessibilityNotification.Announcement(String(localized: Self.unsavedNote(label))).post()
            }
        }
    }

    /// Shown, as in the logger, when an added context was picked but couldn't be saved to the person's list.
    private static func unsavedNote(_ label: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "checkIn.context.notSaved",
            defaultValue: "Couldn't save \"\(label)\" to your list, but it's in this check-in.",
        )
    }
}

#if DEBUG
    #Preview {
        CheckInView {}
            .modelContainer(AppModelContainer.preview)
    }
#endif
