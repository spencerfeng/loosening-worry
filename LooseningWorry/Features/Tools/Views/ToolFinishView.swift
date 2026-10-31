import SwiftUI

/// After a run: "How do you feel now?", a word for the answer, and what to do next. Answering is optional.
struct ToolFinishView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let model: ToolRunViewModel
    let done: () -> Void
    /// "Try another tool" swaps the buttons for the other tools.
    @State private var isPickingTool = false
    @State private var isShowingHelp = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(LocalizedStringResource("tool.finish.title", defaultValue: "How do you feel now?"))
                        .font(.theme(.title))
                        .foregroundStyle(.theme(.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                    Text(LocalizedStringResource("tool.finish.detail", defaultValue: "Compared to when you started."))
                        .font(.theme(.body))
                        .foregroundStyle(.theme(.textSecondary))
                }
                .multilineTextAlignment(.center)

                FeelingPicker(feeling: model.feeling) { model.choose($0) }

                // Quietly, so a failed save doesn't spoil the moment; the rest of the screen works as ever.
                if let failure = model.saveFailure {
                    Text(failure == .session
                        ? LocalizedStringResource("tool.finish.notSaved", defaultValue: "Couldn't save this session.")
                        : LocalizedStringResource(
                            "tool.finish.answerNotSaved",
                            defaultValue: "Couldn't save your answer.",
                        ))
                        .font(.theme(.footnote))
                        .foregroundStyle(.theme(.textTertiary))
                }

                if let feeling = model.feeling {
                    FeelingMessage(
                        text: model.tool.finishMessage(for: feeling),
                        suggestedTool: model.suggestedTool,
                        tryTool: { model.start($0, now: .now) },
                        getHelp: { isShowingHelp = true },
                    )
                    .id(feeling)
                    .transition(reveal)
                }

                if let tally = model.lighterTally {
                    LighterTallyCard(tool: model.tool, tally: tally)
                        .transition(reveal)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .animation(.easeOut(duration: 0.3), value: model.feeling)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 6) {
                if isPickingTool {
                    OtherTools(current: model.tool) { model.start($0, now: .now) }
                }
                Button(action: done) {
                    Text(LocalizedStringResource("tool.finish.done", defaultValue: "Done"))
                        .font(.theme(.headline))
                        .foregroundStyle(.theme(.textOnAccent))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.theme(.accent), in: .capsule)
                        .shadow(color: .theme(.accentShadow), radius: 8, y: 6)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                if !isPickingTool {
                    Button {
                        isPickingTool = true
                    } label: {
                        Text(LocalizedStringResource("tool.finish.another", defaultValue: "Try another tool"))
                            .font(.theme(.callout))
                            .foregroundStyle(.theme(.accentText))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.theme(.background))
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                ToolPill(
                    text: LocalizedStringResource("tool.finish.pill", defaultValue: "Session complete"),
                    ink: .accentText,
                    tint: .accentTint,
                )
            }
        }
        .sheet(isPresented: $isShowingHelp) {
            HelpView()
        }
    }

    /// How the answer's message and tally come in: rising into place, or only fading with Reduce Motion.
    private var reveal: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8))
    }
}

/// Lighter, About the same, Heavier: one choice, which can be changed. Side by side, or stacked as rows at
/// accessibility sizes so the words aren't broken.
private struct FeelingPicker: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let feeling: Feeling?
    let choose: (Feeling) -> Void

    var body: some View {
        let isStacked = dynamicTypeSize.isAccessibilitySize
        let choices = isStacked ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
        let face = isStacked ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 8))
        choices {
            ForEach([Feeling.lighter, .same, .heavier], id: \.self) { option in
                let isChosen = feeling == option
                Button {
                    choose(option)
                } label: {
                    face {
                        FeelingFace(feeling: option)
                            .stroke(style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .accessibilityHidden(true)
                        Text(option.label)
                            .font(.theme(.callout))
                            .multilineTextAlignment(isStacked ? .leading : .center)
                        if isStacked {
                            Spacer(minLength: 0)
                        }
                    }
                    .foregroundStyle(.theme(isChosen ? .textOnAccent : .textPrimary))
                    .padding(.vertical, 12)
                    .padding(.horizontal, isStacked ? 16 : 6)
                    .frame(maxWidth: .infinity, minHeight: isStacked ? 64 : 120)
                    .background(.theme(isChosen ? .accent : .surface), in: .rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20).strokeBorder(.theme(isChosen ? .accent : .borderSubtle))
                    }
                    .scaleEffect(isChosen ? 1.04 : 1)
                    .contentShape(.rect(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
        }
        .animation(.easeOut(duration: 0.15), value: feeling)
        .sensoryFeedback(.selection, trigger: feeling)
    }
}

/// "Get curious has left you lighter 5 of 7 times", on the tool's tint behind the Lighter face.
private struct LighterTallyCard: View {
    let tool: QuickTool
    let tally: LighterTally

    var body: some View {
        HStack(spacing: 14) {
            FeelingFace(feeling: .lighter)
                .stroke(style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
                .frame(width: 26, height: 26)
                .foregroundStyle(.theme(tool.ink))
                .frame(width: 40, height: 40)
                .background(.theme(.surface), in: .circle)
                .accessibilityHidden(true)
            Text(text)
                .font(.theme(.body))
                .foregroundStyle(.theme(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(.theme(tool.tint), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private var text: AttributedString {
        tally.sentence(naming: tool).restylingEmphasis(font: .theme(.headline), color: .theme(tool.onTint))
    }
}

/// What the answer means; after Heavier, a tool to try and the way to Help.
private struct FeelingMessage: View {
    let text: LocalizedStringResource
    let suggestedTool: QuickTool?
    let tryTool: (QuickTool) -> Void
    let getHelp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textPrimary))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let suggestedTool {
                FlowLayout(spacing: 8) {
                    Button {
                        tryTool(suggestedTool)
                    } label: {
                        Text(LocalizedStringResource(
                            "tool.finish.try",
                            defaultValue: "Try \(String(localized: suggestedTool.name))",
                        ))
                        .font(.theme(.callout))
                        .foregroundStyle(.theme(suggestedTool.onTint))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(.theme(suggestedTool.tint), in: .capsule)
                        .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    Button(action: getHelp) {
                        Text(LocalizedStringResource("tool.finish.help", defaultValue: "Get help"))
                            .font(.theme(.callout))
                            .foregroundStyle(.theme(.help))
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background(.theme(.surface), in: .capsule)
                            .overlay { Capsule().strokeBorder(.theme(.border)) }
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(.theme(.surface), in: .rect(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.theme(.borderSubtle)) }
        .accessibilityElement(children: .contain)
    }
}

/// The tools other than the one just used, to start straight away.
private struct OtherTools: View {
    let current: QuickTool
    let start: (QuickTool) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(QuickTool.allCases.filter { $0 != current }, id: \.self) { tool in
                Button {
                    start(tool)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tool.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.theme(tool.ink))
                            .frame(width: 32, height: 32)
                            .background(.theme(tool.tint), in: .rect(cornerRadius: 10))
                            .accessibilityHidden(true)
                        Text(tool.name)
                            .font(.theme(.subheadline))
                            .foregroundStyle(.theme(.textPrimary))
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 52)
                    .background(.theme(.surface), in: .rect(cornerRadius: 16))
                    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.theme(.borderSubtle)) }
                    .contentShape(.rect(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 6)
    }
}

private extension Feeling {
    var label: LocalizedStringResource {
        switch self {
        case .lighter: LocalizedStringResource("tool.feeling.lighter", defaultValue: "Lighter")
        case .same: LocalizedStringResource("tool.feeling.same", defaultValue: "About the same")
        case .heavier: LocalizedStringResource("tool.feeling.heavier", defaultValue: "Heavier")
        }
    }
}

/// The finish screen's words for each answer. Lighter names what the tool gave; the others fit every tool, except
/// that Heavier after Breathe points to curiosity rather than breathing again. All are drafts for the reviewer.
private extension QuickTool {
    func finishMessage(for feeling: Feeling) -> LocalizedStringResource {
        switch (feeling, self) {
        case (.lighter, .curious):
            LocalizedStringResource(
                "tool.finish.lighter.curious",
                defaultValue: "That's curiosity at work. Your brain just noticed it feels better than worry.",
            )
        case (.lighter, .breathe):
            LocalizedStringResource(
                "tool.finish.lighter.breathe",
                defaultValue: "That's your breath at work. Your brain just noticed calm feels better than worry.",
            )
        case (.lighter, .noteIt):
            LocalizedStringResource(
                "tool.finish.lighter.noteIt",
                defaultValue: "That's noticing at work. Naming what's here gave your brain a step back from worry.",
            )
        case (.lighter, .beKind):
            LocalizedStringResource(
                "tool.finish.lighter.beKind",
                defaultValue: "That's kindness at work. Your brain just noticed warmth feels better than worry.",
            )
        case (.same, _):
            LocalizedStringResource(
                "tool.finish.same",
                defaultValue: "That's okay. Noticing without fighting is the practice, and it gets easier each time.",
            )
        case (.heavier, .breathe):
            LocalizedStringResource(
                "tool.finish.heavier.breathe",
                defaultValue: """
                Some moments are just hard, and that's fine. Getting curious about the feeling can help, or reach out \
                for more support.
                """,
            )
        case (.heavier, _):
            LocalizedStringResource(
                "tool.finish.heavier",
                defaultValue: """
                Some moments are just hard, and that's fine. A minute of breathing can help, or reach out for more \
                support.
                """,
            )
        }
    }
}
