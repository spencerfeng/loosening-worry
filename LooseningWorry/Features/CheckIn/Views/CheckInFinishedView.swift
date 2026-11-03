import SwiftData
import SwiftUI

/// After a check-in is saved: what was named, a line about it, and on the unpleasant side a tool to try, the other
/// tools, a way into the logger and, when it's very unpleasant, Help.
struct CheckInFinishedView: View {
    @Environment(\.modelContext) private var modelContext
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State private var runningTool: QuickTool?
    @State private var isShowingHelp = false
    /// Set on appear, to play the success haptic once.
    @State private var hasAppeared = false

    let model: CheckInViewModel
    let suggestion: CheckInSuggestion
    let logLoop: () -> Void
    let done: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                summary
                if let tool = suggestion.tool {
                    TryATool(tool: tool, start: { runningTool = $0 }, logLoop: logLoop)
                }
                if suggestion.showsHelp {
                    HelpLine { isShowingHelp = true }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SecondaryButton(
                title: LocalizedStringResource("checkIn.finished.done", defaultValue: "Done"),
                action: done,
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.theme(.background))
        }
        .background(.theme(.background))
        .fullScreenCover(item: $runningTool) { tool in
            ToolRunView(tool: tool, sessions: SessionStore(context: modelContext))
        }
        .sheet(isPresented: $isShowingHelp) {
            HelpView()
        }
        .sensoryFeedback(.success, trigger: hasAppeared)
        .onAppear {
            isTitleFocused = true
            hasAppeared = true
        }
    }

    private var summary: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.theme(.greenStrong))
                .frame(width: 64, height: 64)
                .background(.theme(.greenTint), in: .circle)
                .accessibilityHidden(true)
            Text(LocalizedStringResource("checkIn.finished.title", defaultValue: "Checked in"))
                .font(.theme(.title))
                .foregroundStyle(.theme(.textPrimary))
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isTitleFocused)
            FlowLayout(spacing: 6, alignment: .center) {
                ForEach(Array(model.summary.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.theme(.footnote))
                        .fontWeight(.bold)
                        .foregroundStyle(.theme(.textSecondary))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.theme(.surfaceSunken), in: .capsule)
                }
            }
            // Read once, as a list, rather than chip by chip.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(model.summary.map { String(localized: $0) }.formatted(.list(type: .and))))
            if let line = model.closingLine {
                Text(line)
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textSecondary))
                    .lineSpacing(4)
                    .frame(maxWidth: 320)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

/// The suggested tool as a card, the other three as chips, and the way into the logger.
private struct TryATool: View {
    let tool: QuickTool
    let start: (QuickTool) -> Void
    let logLoop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(LocalizedStringResource("checkIn.finished.tryATool", defaultValue: "Try a tool"))
            ToolCard(tool: tool, detail: tool.checkInReason) { start(tool) }
            FlowLayout(spacing: 8) {
                Text(LocalizedStringResource("checkIn.finished.or", defaultValue: "Or:"))
                    .font(.theme(.callout))
                    .foregroundStyle(.theme(.textTertiary))
                    .frame(minHeight: 44)
                ForEach(QuickTool.allCases.filter { $0 != tool }, id: \.self) { other in
                    ChipButton(other.name) { start(other) }
                }
            }
            Button(action: logLoop) {
                Text(LocalizedStringResource("checkIn.finished.logLoop", defaultValue: "Caught in a loop? Log it"))
                    .font(.theme(.callout))
                    .foregroundStyle(.theme(.accentText))
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

/// A quiet pointer to Help, in Help's own color (ADR 0001).
private struct HelpLine: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "lifepreserver")
                    .foregroundStyle(.theme(.help))
                    .accessibilityHidden(true)
                Text(LocalizedStringResource(
                    "checkIn.finished.help",
                    defaultValue: "If it feels like too much, Help has people you can talk to.",
                ))
                .foregroundStyle(.theme(.textSecondary))
                .multilineTextAlignment(.leading)
            }
            .font(.theme(.callout))
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(LocalizedStringResource("checkIn.finished.help.hint", defaultValue: "Opens Help")))
    }
}

/// Why each tool suits what was named, under its name on the card. Drafts for the reviewer.
private extension QuickTool {
    var checkInReason: LocalizedStringResource {
        switch self {
        case .curious:
            LocalizedStringResource(
                "checkIn.reason.curious",
                defaultValue: "Look at the worry instead of being pulled along by it",
            )
        case .breathe: LocalizedStringResource("checkIn.reason.breathe", defaultValue: "Slow down with your breath")
        case .noteIt:
            LocalizedStringResource("checkIn.reason.noteIt", defaultValue: "Name what's here, one word at a time")
        case .beKind:
            LocalizedStringResource("checkIn.reason.beKind", defaultValue: "Meet the harsh inner voice with warmth")
        }
    }
}

#if DEBUG
    #Preview("Unpleasant") {
        let model = CheckInViewModel()
        model.choose(.veryUnpleasant)
        model.next()
        model.toggle(.anxious)
        model.toggle(.overwhelmed)
        model.finish { _ in }
        let suggestion = model.suggestion ?? CheckInSuggestion(for: CheckInAnswer(pleasantness: .neutral, feelings: []))
        return CheckInFinishedView(model: model, suggestion: suggestion, logLoop: {}, done: {})
            .modelContainer(AppModelContainer.preview)
    }

    #Preview("Pleasant") {
        let model = CheckInViewModel()
        model.choose(.pleasant)
        model.next()
        model.toggle(.calm)
        model.finish { _ in }
        let suggestion = model.suggestion ?? CheckInSuggestion(for: CheckInAnswer(pleasantness: .neutral, feelings: []))
        return CheckInFinishedView(model: model, suggestion: suggestion, logLoop: {}, done: {})
            .modelContainer(AppModelContainer.preview)
    }
#endif
