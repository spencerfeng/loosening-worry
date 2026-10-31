import SwiftUI

// The pictures in onboarding's panels. The two drawings use the lesson pictures' loop colors: amber sets it off, violet
// is what you do, green is what it gives. Drawn on the design's grid and scaled down to fit narrower phones; with
// Reduce Motion they hold still.

/// Welcome: the loop breaking open, a calm face inside, and the three loop colors drifting free.
struct WelcomeArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    var body: some View {
        ArtCanvas(size: CGSize(width: 340, height: 260)) {
            Circle()
                .trim(from: 30 / 360, to: 330 / 360)
                .stroke(.theme(.accentOutline), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 140, height: 140)
                .position(x: 148, y: 130)
            LoopTail()
                .stroke(
                    LinearGradient(
                        colors: [.theme(.accentOutline), .theme(.accentOutline).opacity(0)],
                        startPoint: UnitPoint(x: 0.61, y: 0.5),
                        endPoint: .trailing,
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round),
                )
            Arrowhead()
                .fill(.theme(.accentSoft))
                .frame(width: 16, height: 14)
                .rotationEffect(.degrees(90))
                .position(x: 78, y: 130)
            Circle()
                .fill(.theme(.surface))
                .frame(width: 80, height: 80)
                .position(x: 148, y: 130)
            CalmFace()
                .stroke(.theme(.accentText), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
                .frame(width: 80, height: 80)
                .position(x: 148, y: 130)
            ForEach(Array(Self.drifting.enumerated()), id: \.offset) { index, dot in
                Circle()
                    .fill(.theme(dot.color))
                    .frame(width: dot.size, height: dot.size)
                    .offset(y: isFloating ? -6 : 0)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever().delay(Double(index) * 0.4),
                        value: isFloating,
                    )
                    .position(dot.center)
            }
            Sparkle().fill(.theme(.amberFill)).frame(width: 22, height: 22).position(x: 68, y: 38)
            Sparkle().fill(.theme(.greenFill)).frame(width: 16, height: 16).position(x: 52, y: 216)
            Sparkle().fill(.theme(.violetStrong)).frame(width: 19, height: 19).position(x: 298, y: 209)
        }
        .frame(height: 288)
        .accessibilityHidden(true)
        .onAppear { isFloating = true }
    }

    private static let drifting: [(color: Theme.ColorRole, size: CGFloat, center: CGPoint)] = [
        (.amberFill, 30, CGPoint(x: 244, y: 92)),
        (.violetStrong, 22, CGPoint(x: 284, y: 70)),
        (.greenFill, 16, CGPoint(x: 316, y: 50)),
    ]
}

/// The loop: what sets you off, what you do and what it gives you, round a ring with arrows showing the way. A dot
/// goes round and each stop pops as it arrives (`LoopLap`); with Reduce Motion the loop holds still, without the dot.
struct LoopArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now
    private static let center = CGPoint(x: 175, y: 170)
    private static let radius: CGFloat = 100

    var body: some View {
        Group {
            if reduceMotion {
                drawing(dotAngle: nil)
            } else {
                TimelineView(.animation) { context in
                    drawing(dotAngle: LoopLap.dotAngle(after: context.date.timeIntervalSince(start)))
                }
            }
        }
        .frame(height: 300)
        .accessibilityElement()
        .accessibilityLabel(Text(LocalizedStringResource(
            "onboarding.loop.description",
            defaultValue: "A loop: lying awake, then going over tomorrow, then feeling more awake, and round again.",
        )))
    }

    private func drawing(dotAngle: Double?) -> some View {
        ArtCanvas(size: CGSize(width: 350, height: 330)) {
            Circle()
                .stroke(.theme(.accentOutline), lineWidth: 12)
                .frame(width: Self.radius * 2, height: Self.radius * 2)
                .position(Self.center)
            ForEach([-30.0, 90, 210], id: \.self) { degrees in
                Arrowhead()
                    .fill(.theme(.accentSoft))
                    .frame(width: 16, height: 14)
                    .rotationEffect(.degrees(degrees + 90))
                    .position(Self.point(at: degrees))
            }
            if let dotAngle {
                Circle()
                    .fill(.theme(.accent))
                    .frame(width: 16, height: 16)
                    .position(Self.point(at: dotAngle))
            }
            LoopStop(fill: .amberFill) {
                Image(systemName: "moon").font(.system(size: 24, weight: .semibold))
            }
            .scaleEffect(Self.scale(ofStopAt: -90, dotAngle: dotAngle))
            .position(Self.point(at: -90))
            LoopStop(fill: .violetStrong) {
                Image(systemName: "arrow.clockwise").font(.system(size: 24, weight: .semibold))
            }
            .scaleEffect(Self.scale(ofStopAt: 30, dotAngle: dotAngle))
            .position(Self.point(at: 30))
            LoopStop(fill: .greenFill) {
                FeelingFace(feeling: .heavier)
                    .stroke(style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .frame(width: 34, height: 34)
            }
            .scaleEffect(Self.scale(ofStopAt: 150, dotAngle: dotAngle))
            .position(Self.point(at: 150))
            LoopLabel(
                caption: LocalizedStringResource("onboarding.loop.trigger", defaultValue: "Sets you off"),
                label: LocalizedStringResource("onboarding.loop.trigger.example", defaultValue: "Lying awake"),
            )
            .position(x: 175, y: 22)
            LoopLabel(
                caption: LocalizedStringResource("onboarding.loop.behavior", defaultValue: "You do"),
                label: LocalizedStringResource("onboarding.loop.behavior.example", defaultValue: "Go over tomorrow"),
            )
            .position(x: Self.point(at: 30).x, y: 284)
            LoopLabel(
                caption: LocalizedStringResource("onboarding.loop.result", defaultValue: "It gives you"),
                label: LocalizedStringResource("onboarding.loop.result.example", defaultValue: "More awake"),
            )
            .position(x: Self.point(at: 150).x, y: 284)
        }
    }

    private static func scale(ofStopAt stopAngle: Double, dotAngle: Double?) -> Double {
        dotAngle.map { LoopLap.scale(ofStopAt: stopAngle, dotAngle: $0) } ?? 1
    }

    /// The point on the ring at `degrees`, clockwise from three o'clock.
    private static func point(at degrees: Double) -> CGPoint {
        let angle = degrees * .pi / 180
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
}

private struct LoopStop<Icon: View>: View {
    let fill: Theme.ColorRole
    @ViewBuilder let icon: Icon

    var body: some View {
        icon
            .foregroundStyle(.white)
            .frame(width: 60, height: 60)
            .background(.theme(fill), in: .circle)
    }
}

/// Labels inside the drawing stop growing at the largest text sizes, where they'd run into each other; the drawing's
/// description reads the same words.
private struct LoopLabel: View {
    let caption: LocalizedStringResource
    let label: LocalizedStringResource

    var body: some View {
        VStack(spacing: 2) {
            Text(caption)
                .font(.theme(.caption2))
                .fontWeight(.heavy)
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundStyle(.theme(.accentText))
            Text(label)
                .font(.theme(.callout))
                .foregroundStyle(.theme(.textPrimary))
        }
        .fixedSize()
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

/// When worry shows up: catch it, ease it, see it.
struct UsesPanel: View {
    var body: some View {
        PanelRows {
            PanelRow(
                title: LocalizedStringResource("onboarding.uses.catch", defaultValue: "Catch it"),
                line: LocalizedStringResource("onboarding.uses.catch.line", defaultValue: "Log a loop in 20 seconds"),
            ) { PulsingLogButton() }
            PanelRow(
                title: LocalizedStringResource("onboarding.uses.ease", defaultValue: "Ease it"),
                line: LocalizedStringResource("onboarding.uses.ease.line", defaultValue: "Try a quick tool"),
            ) { BobbingTools() }
            PanelRow(
                title: LocalizedStringResource("onboarding.uses.see", defaultValue: "See it"),
                line: LocalizedStringResource("onboarding.uses.see.line", defaultValue: "Spot your patterns"),
            ) { GrowingBars() }
        }
    }
}

/// Good to know: what the app isn't, and where Help is. Needs the clinician's review before launch.
struct GoodToKnowPanel: View {
    var body: some View {
        PanelRows {
            PanelRow(
                title: LocalizedStringResource(
                    "onboarding.goodToKnow.selfHelp",
                    defaultValue: "Self-help, not therapy",
                ),
                line: LocalizedStringResource(
                    "onboarding.goodToKnow.selfHelp.line",
                    defaultValue: "It doesn't replace a doctor or therapist.",
                ),
            ) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.theme(.accentText))
            }
            PanelRow(
                title: LocalizedStringResource("onboarding.goodToKnow.help", defaultValue: "Help is one tap away"),
                line: LocalizedStringResource(
                    "onboarding.goodToKnow.help.line",
                    defaultValue: "Crisis lines, any time. Top right of Home.",
                ),
            ) {
                Image(systemName: "lifepreserver")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.theme(.help))
            }
        }
    }
}

private struct PanelRows<Rows: View>: View {
    @ViewBuilder let rows: Rows

    var body: some View {
        VStack(spacing: 10) {
            rows
        }
        .frame(maxHeight: .infinity)
    }
}

/// A white strip in a panel: a small picture, a bold label and a short line.
private struct PanelRow<Picture: View>: View {
    let title: LocalizedStringResource
    let line: LocalizedStringResource
    @ViewBuilder let picture: Picture

    var body: some View {
        HStack(spacing: 14) {
            picture
                .frame(width: 76, height: 60)
                .background(.theme(.background), in: .rect(cornerRadius: 14))
                .clipped()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.theme(.headline))
                    .fontWeight(.heavy)
                    .foregroundStyle(.theme(.textPrimary))
                Text(line)
                    .font(.theme(.subheadline))
                    .fontWeight(.regular)
                    .foregroundStyle(.theme(.textSecondary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 14))
        .background(.theme(.surface), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

/// The Log a loop button, gently pulsing.
private struct PulsingLogButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        Image(systemName: "square.and.pencil")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.theme(.textOnAccent))
            .frame(width: 40, height: 40)
            .background(.theme(.accent), in: .circle)
            .scaleEffect(isPulsing ? 1.08 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

/// The four tools in their own colors, as they look on Home, bobbing in turn.
private struct BobbingTools: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBobbing = false

    var body: some View {
        Grid(horizontalSpacing: 5, verticalSpacing: 5) {
            ForEach([[QuickTool.curious, .breathe], [.noteIt, .beKind]], id: \.self) { pair in
                GridRow {
                    ForEach(pair, id: \.self) { tool in
                        Image(systemName: tool.symbol)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.theme(tool.ink))
                            .frame(width: 22, height: 22)
                            .background(.theme(tool.tint), in: .circle)
                            .offset(y: isBobbing ? -3 : 0)
                            .animation(
                                reduceMotion ? nil : .easeInOut(duration: 1.1).repeatForever()
                                    .delay(Double(QuickTool.allCases.firstIndex(of: tool) ?? 0) * 0.3),
                                value: isBobbing,
                            )
                    }
                }
            }
        }
        .onAppear { isBobbing = true }
    }
}

/// A small bar chart, its bars rising and settling.
private struct GrowingBars: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isGrown = false
    private let heights: [CGFloat] = [16, 26, 20, 34, 22]

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(heights.indices, id: \.self) { index in
                Capsule()
                    .fill(.theme(.accent).opacity(index == 3 ? 1 : 0.35))
                    .frame(width: 8, height: heights[index])
                    .scaleEffect(y: isGrown || reduceMotion ? 1 : 0.15, anchor: .bottom)
                    .animation(
                        reduceMotion ? nil : .easeOut(duration: 0.8).repeatForever().delay(Double(index) * 0.12),
                        value: isGrown,
                    )
            }
        }
        .frame(height: 34, alignment: .bottom)
        .onAppear { isGrown = true }
    }
}

/// Draws `content` on a fixed design grid, placed with `position`, and scales it down when the panel is narrower.
private struct ArtCanvas<Content: View>: View {
    let size: CGSize
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            let scale = min(1, proxy.size.width / size.width, proxy.size.height / size.height)
            ZStack(alignment: .topLeading) {
                content
            }
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

/// The welcome loop's loose end, trailing off to the right, on the welcome grid.
private struct LoopTail: Shape {
    func path(in _: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 208.6, y: 165))
        path.addCurve(to: CGPoint(x: 266, y: 132), control1: CGPoint(x: 220, y: 146), control2: CGPoint(x: 240, y: 130))
        path.addCurve(to: CGPoint(x: 334, y: 136), control1: CGPoint(x: 292, y: 134), control2: CGPoint(x: 308, y: 152))
        return path
    }
}

/// Relaxed closed eyes and a soft smile, on an 80 by 80 grid.
private struct CalmFace: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 80
        var path = Path()
        for eyeX in [20.0, 36.8] {
            path.move(to: CGPoint(x: eyeX, y: 36.4))
            path.addQuadCurve(to: CGPoint(x: eyeX + 7.2, y: 36.4), control: CGPoint(x: eyeX + 3.6, y: 31.6))
        }
        path.move(to: CGPoint(x: 31.6, y: 46))
        path.addQuadCurve(to: CGPoint(x: 48.4, y: 46), control: CGPoint(x: 40, y: 55))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

/// A triangle pointing right, rotated to follow a ring.
private struct Arrowhead: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The lesson pictures' four-pointed sparkle.
private struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.27
        var path = Path()
        for point in 0 ..< 8 {
            let angle = Double(point) * .pi / 4 - .pi / 2
            let distance = point.isMultiple(of: 2) ? outer : inner
            let corner = CGPoint(x: center.x + distance * cos(angle), y: center.y + distance * sin(angle))
            if point == 0 {
                path.move(to: corner)
            } else {
                path.addLine(to: corner)
            }
        }
        path.closeSubpath()
        return path
    }
}
