import SwiftData
import SwiftUI

/// Shown once a loop is saved: a celebration, the loop, a line about what it gave the person, this week's count and
/// a tool to try.
struct NiceCatchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    let niceCatch: NiceCatch
    let showInsights: () -> Void
    let done: () -> Void
    /// Starts the entrance: the tick pops, the confetti bursts and the count slides up.
    @State private var hasAppeared = false
    /// VoiceOver starts at the title, since the screen replaces the logger without a transition.
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State private var runningTool: QuickTool?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                NiceCatchCelebration(hasAppeared: hasAppeared)
                VStack(spacing: 8) {
                    Text(LocalizedStringResource("niceCatch.title", defaultValue: "Nice catch!"))
                        .font(.theme(.title))
                        .foregroundStyle(.theme(.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($isTitleFocused)
                    LoopChips(labels: niceCatch.chips)
                }
                Text(niceCatch.reflection)
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textSecondary))
                    .lineSpacing(5)
                    .frame(maxWidth: 300)
                WeeklyCount(count: niceCatch.loopsThisWeek, action: showInsights)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared || reduceMotion ? 0 : 8)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringResource("niceCatch.suggestion", defaultValue: "Try something more rewarding"))
                    .textCase(.uppercase)
                    .font(.theme(.footnote))
                    .fontWeight(.bold)
                    .tracking(0.6)
                    .foregroundStyle(.theme(.textTertiary))
                    .accessibilityAddTraits(.isHeader)
                ToolSuggestionCard(suggestion: niceCatch.suggestion) { runningTool = niceCatch.suggestion.tool }
                Button(action: done) {
                    Text(LocalizedStringResource("niceCatch.done", defaultValue: "Done"))
                        .font(.theme(.headline))
                        .foregroundStyle(.theme(.textPrimary))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(.theme(.surface), in: .capsule)
                        .overlay { Capsule().strokeBorder(.theme(.border)) }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.theme(.background))
        }
        .background(.theme(.background))
        .fullScreenCover(item: $runningTool) { tool in
            // The session belongs to the loop just logged.
            ToolRunView(tool: tool, sessions: SessionStore(context: modelContext), loop: niceCatch.loop)
        }
        .sensoryFeedback(.success, trigger: hasAppeared)
        .onAppear {
            isTitleFocused = true
            // Under Reduce Motion everything is simply there; the count still fades in.
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.4).delay(0.5)) {
                hasAppeared = true
            }
        }
    }
}

/// A green tick that pops in, with confetti bursting around it. Decoration only, so VoiceOver skips it.
private struct NiceCatchCelebration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let hasAppeared: Bool
    @State private var popped = false

    var body: some View {
        ZStack {
            ConfettiBurst()
                .scaleEffect(popped || reduceMotion ? 1 : 0.2)
                .opacity(popped || reduceMotion ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6).delay(0.12), value: popped)
            Image(systemName: "checkmark")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(.theme(.textOnAccent))
                .frame(width: 80, height: 80)
                .background(.theme(.greenStrong), in: .circle)
                .shadow(color: .theme(.greenStrong).opacity(0.35), radius: 10, y: 8)
                .scaleEffect(popped || reduceMotion ? 1 : 0.3)
                .opacity(popped || reduceMotion ? 1 : 0)
                // Overshoots a little and settles, like the design's pop.
                .animation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.45), value: popped)
        }
        .frame(width: 150, height: 120)
        .accessibilityHidden(true)
        .onAppear { popped = true }
    }
}

/// The design's confetti: dots and four-point sparkles in the theme's hues, on a 150 by 120 grid.
private struct ConfettiBurst: View {
    private struct Mark {
        let x: CGFloat
        let y: CGFloat
        /// A dot's radius, or how far a sparkle's points reach from its center.
        let size: CGFloat
        let color: Theme.ColorRole
    }

    private static let dots = [
        Mark(x: 22, y: 40, size: 6, color: .amberStrong), Mark(x: 128, y: 34, size: 7, color: .violetStrong),
        Mark(x: 16, y: 88, size: 4, color: .violetStrong), Mark(x: 134, y: 86, size: 5, color: .redStrong),
        Mark(x: 44, y: 12, size: 4, color: .greenStrong), Mark(x: 108, y: 10, size: 5, color: .amberStrong),
    ]

    private static let sparkles = [
        Mark(x: 75, y: 10, size: 8, color: .accent), Mark(x: 140, y: 63.5, size: 5.5, color: .greenStrong),
        Mark(x: 8, y: 67.5, size: 5.5, color: .redStrong),
    ]

    var body: some View {
        Canvas { context, _ in
            for dot in Self.dots {
                let bounds = CGRect(x: dot.x - dot.size, y: dot.y - dot.size, width: dot.size * 2, height: dot.size * 2)
                context.fill(Path(ellipseIn: bounds), with: .color(.theme(dot.color)))
            }
            for sparkle in Self.sparkles {
                context.fill(Self.sparkle(sparkle), with: .color(.theme(sparkle.color)))
            }
        }
        .frame(width: 150, height: 120)
    }

    private static func sparkle(_ mark: Mark) -> Path {
        let (x, y, size) = (mark.x, mark.y, mark.size)
        let waist = size / 4
        var path = Path()
        path.addLines([
            CGPoint(x: x, y: y - size), CGPoint(x: x + waist, y: y - waist),
            CGPoint(x: x + size, y: y), CGPoint(x: x + waist, y: y + waist),
            CGPoint(x: x, y: y + size), CGPoint(x: x - waist, y: y + waist),
            CGPoint(x: x - size, y: y), CGPoint(x: x - waist, y: y - waist),
        ])
        path.closeSubpath()
        return path
    }
}

/// The loop as three chips joined by arrows. VoiceOver reads the three in order.
private struct LoopChips: View {
    let labels: [String]

    var body: some View {
        FlowLayout(spacing: 6, alignment: .center) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index > 0 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.theme(.textTertiary))
                        .frame(height: 28)
                }
                Text(label)
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.accentPressed))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(.theme(.accentTint), in: .rect(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(labels.joined(separator: ", ")))
    }
}

/// "10 loops noticed this week +1": the count includes the loop just saved, which the +1 marks. Opens Insights.
private struct WeeklyCount: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(sentence)
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textSecondary))
                Text(verbatim: "+1")
                    .font(.theme(.footnote))
                    .fontWeight(.heavy)
                    .foregroundStyle(.theme(.greenStrong))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .background(.theme(.greenTint), in: .capsule)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(.theme(.surface), in: .rect(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.theme(.borderSubtle)) }
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(LocalizedStringResource("niceCatch.count.hint", defaultValue: "Opens Insights")))
    }

    /// The count is the strong run of a plural sentence, so translators keep it in the right place.
    private var sentence: AttributedString {
        AttributedString(
            localized: LocalizedStringResource(
                "niceCatch.count",
                defaultValue: "**\(count)** loops noticed this week",
            )
        )
        .restylingEmphasis(font: .theme(.title3), color: .theme(.accentText))
    }
}

/// The suggested tool, as a card that starts it.
private struct ToolSuggestionCard: View {
    let suggestion: NiceCatch.ToolSuggestion
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
        HStack(spacing: 12) {
            Image(systemName: suggestion.tool.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.theme(suggestion.tool.ink))
                .frame(width: 40, height: 40)
                .background(.theme(suggestion.tool.tint), in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.name)
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textPrimary))
                Text(suggestion.detail)
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textTertiary))
            }
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(minHeight: 64)
        .background(.theme(.surface), in: .rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.theme(.borderSubtle)) }
        .contentShape(.rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
    #Preview {
        NiceCatchView(
            niceCatch: NiceCatch(
                loop: Loop(
                    trigger: OptionChoice(.work, label: "Work"),
                    behavior: OptionChoice(.overthought, label: "Overthought it"),
                    result: OptionChoice(.moreWorry, label: "More worry"),
                ),
                loopsThisWeek: 10,
            ),
            showInsights: {},
            done: {},
        )
    }
#endif
