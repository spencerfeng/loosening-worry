import SwiftData
import SwiftUI

/// The shell every tool runs in, full screen: Close, the tool's name, End, and what its pacing needs. A timed tool
/// has a bar with the time and Play, so the person starts when they're ready; a counted tool shows its time in the
/// header; a paged tool shows none. On End, or when a timed tool's time is up, the finish screen asks how the person
/// feels now.
struct ToolRunView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: ToolRunViewModel

    init(tool: QuickTool) {
        _model = State(initialValue: ToolRunViewModel(tool: tool, now: .now, picker: .standard, lengths: .standard))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch model.stage {
                case .running: running
                case .finished: ToolFinishView(model: model) { dismiss() }
                }
            }
            .background(.theme(.background))
            .navigationBarTitleDisplayMode(.inline)
        }
        // A soft tap when the time runs out; End is the person's own doing, so it needs none.
        .sensoryFeedback(.impact(weight: .light), trigger: model.stage) { _, stage in
            stage == .finished && model.finishedOnTime
        }
        // Only leaving the app pauses: a glance at Control Center or Notification Center (inactive) doesn't.
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: model.returnToApp(now: .now)
            case .background: model.leaveApp(now: .now)
            default: break
            }
        }
    }

    private var running: some View {
        ToolBody(model: model)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if model.tool.pacing == .timed, let length = model.length {
                    ToolControls(model: model, length: length) {
                        ToolSideControl(model: model)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    ToolRunPill(model: model)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        model.end(now: .now)
                    } label: {
                        Text(LocalizedStringResource("tool.end", defaultValue: "End"))
                    }
                    .tint(.theme(.accentText))
                }
            }
            // Keeps the timer moving while the run is on screen and not paused.
            .task(id: model.isPaused) {
                while !model.isPaused, model.stage == .running {
                    model.tick(now: .now)
                    do {
                        try await Task.sleep(for: .milliseconds(250))
                    } catch {
                        return
                    }
                }
            }
    }
}

/// The run's header: the tool's name, with a counted tool's time beside it ("Note it · 0:42 / 1:30", just
/// "Note it · 1:52" once past its length), since it has no bar to show it. Until its first tap starts the time it shows
/// only the target ("Note it · 1:30"), rather than a "0:00" that looks stuck. A timed tool's bar already shows its
/// time.
/// Only a counted tool's pill reads the clock, so the others aren't redrawn as it ticks.
private struct ToolRunPill: View {
    let model: ToolRunViewModel

    var body: some View {
        ToolPill(text: text, ink: model.tool.onTint, tint: model.tool.tint)
            .accessibilityAddTraits(model.tool.pacing == .counted ? .updatesFrequently : [])
    }

    private var text: LocalizedStringResource {
        let tool = model.tool
        guard tool.pacing == .counted, let length = tool.length else { return tool.name }
        let name = String(localized: tool.name)
        let lengthText = length.formatted(.time(pattern: .minuteSecond))
        guard model.hasStarted else {
            return LocalizedStringResource("tool.run.countedTarget", defaultValue: "\(name) · \(lengthText)")
        }
        let elapsedText = model.elapsed.formatted(.time(pattern: .minuteSecond))
        return !model.isPastLength
            ? LocalizedStringResource("tool.run.counted", defaultValue: "\(name) · \(elapsedText) / \(lengthText)")
            : LocalizedStringResource("tool.run.countedPast", defaultValue: "\(name) · \(elapsedText)")
    }
}

/// A pill in the header: the run's tool in its own hue, or "Session complete" in the accent.
struct ToolPill: View {
    let text: LocalizedStringResource
    let ink: Theme.ColorRole
    let tint: Theme.ColorRole

    var body: some View {
        Text(text)
            .font(.theme(.subheadline))
            .foregroundStyle(.theme(ink))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(.theme(tint), in: .capsule)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The tool itself, which drives the run: a counted tool starts its timer on its first tap. Each tool takes its place
/// here as it's built.
private struct ToolBody: View {
    @Environment(\.modelContext) private var modelContext

    let model: ToolRunViewModel

    var body: some View {
        switch model.tool {
        case .curious: CuriousView(model: model)
        case .breathe: BreatheView(model: model)
        case .noteIt: NoteItView(model: model)
        case .beKind: BeKindView(model: model, store: PhraseStore(context: modelContext))
        }
    }
}

/// A timed tool's own button left of Play: Get curious's Back 15, Breathe's length. Each tool adds its own here as
/// it's built.
private struct ToolSideControl: View {
    let model: ToolRunViewModel

    var body: some View {
        switch model.tool {
        case .curious: BackButton(model: model)
        case .breathe: LengthMenu(model: model)
        case .noteIt, .beKind: EmptyView()
        }
    }
}

/// Back 15, for a prompt missed or read too fast.
private struct BackButton: View {
    let model: ToolRunViewModel

    var body: some View {
        Button {
            model.goBack(now: .now)
        } label: {
            Image(systemName: "gobackward.15")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.theme(.textPrimary))
                .frame(width: 48, height: 48)
                .background(.theme(.surfaceSunken), in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .disabled(!model.hasStarted)
        .opacity(model.hasStarted ? 1 : 0.4)
        .accessibilityLabel(Text(LocalizedStringResource("tool.back15", defaultValue: "Back 15 seconds")))
    }
}

/// Breathe's length, chosen before starting from a small menu: 1, 3 or 5 minutes. Greyed out once breathing begins.
private struct LengthMenu: View {
    let model: ToolRunViewModel

    var body: some View {
        Menu {
            Picker(selection: lengthBinding) {
                ForEach(model.lengthOptions, id: \.self) { length in
                    Text(Self.minutes(length)).tag(length)
                }
            } label: {
                Text(LocalizedStringResource("tool.length", defaultValue: "Length"))
            }
        } label: {
            Text(model.length.map(Self.minutes) ?? "")
                .font(.theme(.footnote))
                .foregroundStyle(.theme(.textPrimary))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                // A label inside a small round button: capped, as the system caps its own; VoiceOver reads it whole.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .padding(.horizontal, 4)
                .frame(width: 48, height: 48)
                .background(.theme(.surfaceSunken), in: .circle)
                .contentShape(.circle)
        }
        .disabled(model.hasStarted)
        .opacity(model.hasStarted ? 0.4 : 1)
        .accessibilityLabel(Text(LocalizedStringResource("tool.length", defaultValue: "Length")))
        .accessibilityValue(Text(model.length.map(Self.minutesSpoken) ?? ""))
    }

    private var lengthBinding: Binding<Duration> {
        Binding(get: { model.length ?? .zero }, set: { model.chooseLength($0) })
    }

    /// "1 min", the same short form whatever the number.
    private static func minutes(_ length: Duration) -> String {
        let minutes = Int(length / .seconds(60))
        return String(localized: LocalizedStringResource("tool.length.minutes", defaultValue: "\(minutes) min"))
    }

    /// "1 minute"
    private static func minutesSpoken(_ length: Duration) -> String {
        length.formatted(.units(allowed: [.minutes], width: .wide))
    }
}

/// The progress bar with the time so far and the length, and Play/Pause with the tool's own button on its left. The
/// right-hand slot is kept, so Play stays centered, for Silent mode once a tool makes sound.
private struct ToolControls<Side: View>: View {
    let model: ToolRunViewModel
    let length: Duration
    @ViewBuilder let side: Side

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                ToolProgressBar(progress: model.progress)
                HStack {
                    if let breath = model.breath {
                        // "Breath 3 of 18" and "0:24 / 3:00", as Breathe's design has it.
                        Text(breathText(breath))
                        Spacer()
                        Text(LocalizedStringResource(
                            "tool.time.ofLength",
                            defaultValue: "\(elapsedText) / \(lengthText)",
                        ))
                    } else {
                        Text(elapsedText)
                        Spacer()
                        Text(lengthText)
                    }
                }
                .font(.theme(.footnote))
                .monospacedDigit()
                .foregroundStyle(.theme(.textTertiary))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizedStringResource("tool.time", defaultValue: "Time")))
            .accessibilityValue(Text(timeSpoken))

            HStack(spacing: 24) {
                side
                    .frame(width: 64)
                playButton
                Color.clear
                    .frame(width: 64, height: 1)
            }
        }
        .padding(18)
        .background(.theme(.surface), in: .rect(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.theme(.borderSubtle)) }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        // A tool's words scroll under the bar at large text sizes; this keeps them out of the gaps around it.
        .background(.theme(.background))
    }

    private var elapsedText: String {
        model.elapsed.formatted(.time(pattern: .minuteSecond))
    }

    private var lengthText: String {
        length.formatted(.time(pattern: .minuteSecond))
    }

    private func breathText(_ breath: Breath) -> LocalizedStringResource {
        LocalizedStringResource("tool.breathe.count", defaultValue: "Breath \(breath.number) of \(model.breathCount)")
    }

    private var playButton: some View {
        Button {
            if model.isPaused {
                model.play(now: .now)
            } else {
                model.pause(now: .now)
            }
        } label: {
            Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.theme(.textOnAccent))
                .frame(width: 72, height: 72)
                .background(.theme(.accent), in: .circle)
                .shadow(color: .theme(.accentShadow), radius: 8, y: 6)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playLabel)
    }

    private var playLabel: Text {
        if !model.hasStarted {
            Text(LocalizedStringResource("tool.start", defaultValue: "Start"))
        } else if model.isPaused {
            Text(LocalizedStringResource("tool.resume", defaultValue: "Resume"))
        } else {
            Text(LocalizedStringResource("tool.pause", defaultValue: "Pause"))
        }
    }

    /// "36 seconds of 1 minute, 30 seconds"
    private var timeSpoken: LocalizedStringResource {
        let units = Duration.UnitsFormatStyle(allowedUnits: [.minutes, .seconds], width: .wide)
        let elapsed = model.elapsed.formatted(units)
        let lengthText = length.formatted(units)
        if let breath = model.breath {
            let count = String(localized: breathText(breath))
            return LocalizedStringResource(
                "tool.time.breathValue",
                defaultValue: "\(count), \(elapsed) of \(lengthText)",
            )
        }
        return LocalizedStringResource("tool.time.value", defaultValue: "\(elapsed) of \(lengthText)")
    }
}

private struct ToolProgressBar: View {
    let progress: Double

    var body: some View {
        Capsule()
            .fill(.theme(.border))
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.theme(.accent))
                        .frame(width: proxy.size.width * progress)
                }
            }
    }
}

#if DEBUG
    #Preview {
        ToolRunView(tool: .curious)
    }
#endif
