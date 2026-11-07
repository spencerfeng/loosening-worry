import SwiftData
import SwiftUI

/// After a check-in is saved: what was named, a line about it, and on the unpleasant side a tool to try, the other
/// tools and a way into the logger.
struct CheckInFinishedView: View {
    @Environment(\.modelContext) private var modelContext
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State private var runningTool: QuickTool?
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
                    Text(verbatim: label)
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
            .accessibilityLabel(Text(model.summary.formatted(.list(type: .and))))
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

/// The suggested tool as a card, the other three as tiles, and the way into the logger.
private struct TryATool: View {
    let tool: QuickTool
    let start: (QuickTool) -> Void
    let logLoop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(LocalizedStringResource("checkIn.finished.tryATool", defaultValue: "Try a tool"))
            ToolCard(tool: tool, detail: tool.reason) { start(tool) }
            SectionLabel(LocalizedStringResource("checkIn.finished.orTry", defaultValue: "Or try"))
                .padding(.top, 6)
            OtherTools(tools: QuickTool.allCases.filter { $0 != tool }, start: start)
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

/// The other three tools as equal tiles in a row, each tool's icon over its name; stacked at the largest text sizes so
/// the names aren't cut off.
private struct OtherTools: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let tools: [QuickTool]
    let start: (QuickTool) -> Void

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
        layout {
            ForEach(tools) { tool in
                Button { start(tool) } label: {
                    VStack(spacing: 8) {
                        ToolBadge(tool: tool)
                        Text(tool.name)
                            .font(.theme(.footnote))
                            .fontWeight(.bold)
                            .foregroundStyle(.theme(.textPrimary))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .padding(.horizontal, 6)
                    .cardSurface(cornerRadius: 18)
                    .contentShape(.rect(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
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
