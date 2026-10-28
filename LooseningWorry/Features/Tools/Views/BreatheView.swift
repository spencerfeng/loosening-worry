import SwiftUI

/// Breathe: a circle that grows for 4 seconds and shrinks for 6, saying "Breathe in" and "Breathe out", with a
/// vibration that swells and fades along with it. The pace is fixed; the words below say what to notice, and that
/// anyone it doesn't suit can breathe naturally and watch the circle.
struct BreatheView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: ToolRunViewModel
    @State private var haptics = BreathHaptics()
    /// In or out, as the circle shows it: the words, the turn announcements and the fallback taps all follow the
    /// circle's own clock, so they turn together with it.
    @State private var phase = Breath.Phase.inhale

    var body: some View {
        // Centered when it fits; at large text sizes the words scroll rather than being cut off.
        GeometryReader { proxy in
            ScrollView {
                content
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onChange(of: isRunning) { _, running in
            if running {
                haptics.start { [model] in BreathPattern.offset(at: model.motionTime(at: .now)) }
            } else {
                haptics.stop()
            }
        }
        .onDisappear { haptics.stop() }
        // A phone without Core Haptics taps at each turn instead.
        .sensoryFeedback(.impact(weight: .light), trigger: phase) { _, _ in
            isRunning && !haptics.isSupported
        }
        // Each turn is read out, so the breathing can be followed without seeing the circle.
        .onChange(of: phase) { _, phase in
            if isRunning {
                AccessibilityNotification.Announcement(String(localized: Self.words(for: phase))).post()
            }
        }
    }

    private var isRunning: Bool {
        model.hasStarted && !model.isPaused
    }

    private var content: some View {
        VStack(spacing: 28) {
            // At accessibility sizes the words outgrow the circle, so they sit under it and the circle shrinks.
            let wordsInside = !dynamicTypeSize.isAccessibilitySize
            BreathCircle(model: model, isRunning: isRunning, showsWords: wordsInside, phase: $phase)
                .frame(maxWidth: wordsInside ? 280 : 180)
            // Three levels: the pace as a small label, what to notice as the one sentence to read, and a quieter
            // aside for anyone the pace doesn't suit.
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    if !wordsInside {
                        Text(Self.words(for: phase))
                            .font(.theme(.title2))
                            .foregroundStyle(.theme(.textPrimary))
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: phase)
                            .accessibilityHidden(true)
                    }
                    Text(LocalizedStringResource("tool.breathe.pace", defaultValue: "In for 4 · out for 6"))
                        .font(.theme(.subheadline))
                        .foregroundStyle(.theme(.textTertiary))
                    Text(LocalizedStringResource(
                        "tool.breathe.notice",
                        defaultValue: "Notice the air: a little cooler coming in, warmer going out.",
                    ))
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textSecondary))
                    .lineSpacing(4)
                }
                Text(LocalizedStringResource(
                    "tool.breathe.natural",
                    defaultValue: "If the pace feels off, just breathe naturally and watch the circle.",
                ))
                .font(.theme(.caption))
                .foregroundStyle(.theme(.textTertiary))
                .lineSpacing(2)
            }
            .frame(maxWidth: 300)
            .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    static func words(for phase: Breath.Phase) -> LocalizedStringResource {
        switch phase {
        case .inhale: LocalizedStringResource("tool.breathe.in", defaultValue: "Breathe in")
        case .exhale: LocalizedStringResource("tool.breathe.out", defaultValue: "Breathe out")
        }
    }
}

/// The design's circle and its halo, growing with the in-breath and shrinking with the out-breath. It follows the
/// time spent running, so it holds still on pause, and reports each turn so the words follow it exactly. Under
/// Reduce Motion it stays at rest and only the words change. VoiceOver hears the turns announced instead.
private struct BreathCircle: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let model: ToolRunViewModel
    let isRunning: Bool
    /// "Breathe in" or "Breathe out" inside the circle, unless they're shown under it.
    let showsWords: Bool
    @Binding var phase: Breath.Phase

    var body: some View {
        // Drawn on the design's 280-point grid, then scaled to fit. Under Reduce Motion the clock still ticks, gently,
        // for the words.
        GeometryReader { proxy in
            let scale = min(proxy.size.width, proxy.size.height) / 280
            TimelineView(.animation(minimumInterval: reduceMotion ? 0.1 : nil, paused: !isRunning)) { context in
                let time = model.motionTime(at: context.date)
                let size = reduceMotion ? 0.5 : BreathPattern.size(at: time)
                ZStack {
                    // The design's pale halo, fuller as the breath fills.
                    Circle().fill(.theme(.greenStrong).opacity(0.14 + 0.12 * size))
                        .frame(width: 280 * scale, height: 280 * scale)
                        .scaleEffect(0.7 + 0.38 * size)
                    Circle().fill(.theme(.greenStrong))
                        .frame(width: 220 * scale, height: 220 * scale)
                        .shadow(color: .theme(.greenStrong).opacity(0.35), radius: 15 * scale, y: 10 * scale)
                        .scaleEffect(0.62 + 0.38 * size)
                    if showsWords {
                        Text(BreatheView.words(for: phase))
                            .font(.theme(.title2))
                            .foregroundStyle(.theme(.textOnAccent))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .padding(.horizontal, 24 * scale)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: phase)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .onChange(of: BreathPattern.breath(at: time).phase) { _, turned in
                    phase = turned
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview {
        BreatheView(model: ToolRunViewModel(tool: .breathe, now: .now, picker: .standard, lengths: .standard))
    }
#endif
