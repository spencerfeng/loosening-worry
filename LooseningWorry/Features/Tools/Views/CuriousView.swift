import SwiftUI

/// Get curious: violet rings that pulse gently while it runs, and the prompt for the stage the time
/// is in. Nothing moves as the prompts change: the words keep the height of the session's longest prompt.
struct CuriousView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: ToolRunViewModel

    var body: some View {
        // Centered when it fits; at large text sizes the prompt scrolls rather than being cut off.
        GeometryReader { proxy in
            ScrollView {
                content
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        // A new stage's prompt is read out, since it changes without the person doing anything.
        .onChange(of: prompt.id) {
            let title = String(localized: prompt.title)
            let detail = String(localized: prompt.detail)
            AccessibilityNotification.Announcement(String(localized: LocalizedStringResource(
                "tool.prompt.announcement",
                defaultValue: "\(title) \(detail)",
            ))).post()
        }
    }

    private var content: some View {
        VStack(spacing: 36) {
            CuriousRings(isRunning: model.hasStarted && !model.isPaused) { model.motionTime(at: $0) }
                // Smaller at accessibility sizes, leaving the room to the words.
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 160 : 260)
            ZStack(alignment: .top) {
                // Every prompt of the session, unseen, so the space is the longest one's from the start.
                ForEach(prompts, id: \.id) { prompt in
                    PromptWords(prompt: prompt)
                        .hidden()
                        .accessibilityHidden(true)
                }
                PromptWords(prompt: prompt)
                    .id(prompt.id)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.6), value: prompt.id)
        }
        .padding(24)
    }

    /// The stage's prompt, or the mockup's prompt if the prompts file couldn't be read, so the tool still guides.
    private var prompt: ToolPrompt {
        model.prompt ?? Self.fallback
    }

    private var prompts: [ToolPrompt] {
        model.prompts.isEmpty ? [Self.fallback] : model.prompts
    }

    private static let fallback = ToolPrompt(id: "curious.curious.1")
        ?? { preconditionFailure("Get curious's fallback prompt has no words") }()
}

/// A prompt's line and its guiding sentence.
private struct PromptWords: View {
    let prompt: ToolPrompt

    var body: some View {
        VStack(spacing: 12) {
            Text(prompt.title)
                .font(.theme(.title))
                .foregroundStyle(.theme(.textPrimary))
                .accessibilityAddTraits(.isHeader)
            Text(prompt.detail)
                .font(.theme(.body))
                .foregroundStyle(.theme(.textSecondary))
                .lineSpacing(4)
                .frame(maxWidth: 310)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

/// The design's rings: three violet circles and two small orbs. The design's progress ring is left out, since the bar
/// below already shows the time and a second one drew the eye from the prompt. While the time runs the circles pulse
/// slowly and the orbs travel round them; both follow the run's own time, so on pause they stop where they are and
/// carry on from there. Under Reduce Motion everything stays still. Decoration, so VoiceOver skips it.
private struct CuriousRings: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isRunning: Bool
    /// The run's time at a moment, which the motion follows.
    let time: (Date) -> Duration

    var body: some View {
        // Drawn on the design's 260-point grid, then scaled to fit.
        GeometryReader { proxy in
            let scale = min(proxy.size.width, proxy.size.height) / 260
            TimelineView(.animation(paused: !isRunning || reduceMotion)) { context in
                let seconds = reduceMotion ? 0 : time(context.date) / .seconds(1)
                let pulse = (1 - cos(seconds / Self.breath * 2 * .pi)) / 2
                ZStack {
                    Circle().fill(.theme(.violetTint))
                        .frame(width: 196 * scale, height: 196 * scale)
                        .scaleEffect(1 + 0.04 * pulse)
                    Circle().fill(.theme(.violetStrong).opacity(0.22))
                        .frame(width: 140 * scale, height: 140 * scale)
                        .scaleEffect(1 + 0.06 * pulse)
                    Circle().fill(.theme(.violetStrong))
                        .frame(width: 84 * scale, height: 84 * scale)
                        .scaleEffect(1 + 0.08 * pulse)
                    ForEach(Self.orbs, id: \.size) { orb in
                        let angle = orb.startAngle + seconds / Self.lap * 2 * .pi
                        Circle().fill(.theme(orb.color))
                            .frame(width: orb.size * scale, height: orb.size * scale)
                            .offset(x: cos(angle) * orb.radius * scale, y: sin(angle) * orb.radius * scale)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .frame(maxWidth: 260, maxHeight: 260)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// Seconds for the circles to swell and settle, like a slow breath.
    private static let breath = 6.0
    /// Seconds for an orb to travel once round.
    private static let lap = 45.0

    private struct Orb {
        let size: CGFloat
        let color: Theme.ColorRole
        /// From the center, on the design's grid.
        let radius: CGFloat
        /// Where the design places it, in radians clockwise from the right.
        let startAngle: Double
    }

    /// The design's amber orb top right and green orb bottom left, each on its own path round the circles.
    private static let orbs = [
        Orb(size: 28, color: .amberStrong, radius: 89, startAngle: atan2(-60, 66)),
        Orb(size: 20, color: .greenStrong, radius: 95, startAngle: atan2(66, -68)),
    ]
}

#if DEBUG
    #Preview {
        CuriousView(model: ToolRunViewModel(tool: .curious, now: .now, picker: .standard))
    }
#endif
