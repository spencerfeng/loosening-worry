import SwiftData
import SwiftUI

/// Shown once a loop is saved: a celebration, the loop, what this habit has given the person the last times this
/// trigger set it off, and a tool to try now.
struct NiceCatchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    let niceCatch: NiceCatch
    let done: () -> Void
    /// Starts the entrance: the tick pops, the confetti bursts and the last times slide up.
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
                if let lastTimes = niceCatch.lastTimes {
                    LastTimesCard(lastTimes: lastTimes)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared || reduceMotion ? 0 : 8)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(LocalizedStringResource(
                    "niceCatch.suggestion.now",
                    defaultValue: "Turn toward what's here now",
                ))
                ToolCard(tool: NiceCatch.suggestion, detail: NiceCatch.suggestion.reason) {
                    runningTool = NiceCatch.suggestion
                }
                SecondaryButton(title: LocalizedStringResource("niceCatch.done", defaultValue: "Done"), action: done)
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
            // Under Reduce Motion everything is simply there; the last times still fade in.
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
                // The green is light in dark mode, so the tick takes the page's own color to stand out on it.
                .foregroundStyle(.theme(.background))
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

/// "The last 5 times you overthought it": a dot for what each gave, oldest first, then a line on what it gave most.
/// Just a card: the trigger's page is in Insights.
private struct LastTimesCard: View {
    let lastTimes: LastTimes

    var body: some View {
        InsightsCard(title: lastTimes.title) {
            HStack(spacing: 6) {
                ForEach(Array(lastTimes.outcomes.enumerated()), id: \.offset) { _, outcome in
                    Circle()
                        .fill(.theme(Self.color(outcome)))
                        .frame(width: 14, height: 14)
                }
            }
            // The line says what the dots show.
            .accessibilityHidden(true)
            Text(lastTimes.line.restylingEmphasis(font: .theme(.callout).bold(), color: .theme(.textPrimary)))
                .font(.theme(.callout))
                .foregroundStyle(.theme(.textSecondary))
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }

    private static func color(_ outcome: ResultOutcome) -> Theme.ColorRole {
        switch outcome {
        case .noBetter: .redFill
        case .relief: .greenFill
        case .unclear: .grayFill
        }
    }
}

#if DEBUG
    #Preview {
        let loops = [StarterID.moreWorry, .moreWorry, .littleRelief, .moreWorry, .moreWorry].map { result in
            Loop(
                trigger: OptionChoice(.tryingToSleep, label: "Trying to sleep"),
                behavior: OptionChoice(.overthought, label: "Overthought it"),
                result: OptionChoice(result, label: String(localized: result.label)),
            )
        }
        NiceCatchView(niceCatch: NiceCatch(loop: loops[loops.count - 1], history: loops)) {}
    }
#endif
