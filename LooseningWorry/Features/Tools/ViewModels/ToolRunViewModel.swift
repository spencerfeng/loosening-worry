import Foundation
import Observation

/// One run of a tool in the shared shell: its timer, then the finish screen's "How do you feel now?". The person
/// starts the timer, with Play or a tool's first tap, except in a paged tool, whose time runs from when it opens.
@Observable @MainActor
final class ToolRunViewModel {
    enum Stage {
        case running, finished
    }

    private(set) var tool: QuickTool
    private(set) var stage = Stage.running
    private(set) var elapsed = Duration.zero
    /// The answer to "How do you feel now?"; the person can leave it unanswered.
    private(set) var feeling: Feeling?
    /// Whether the timer has been started yet, so Play can say Start rather than Resume.
    private(set) var hasStarted = false
    /// Whether the run ended because a timed tool's time was up, rather than on End.
    private(set) var finishedOnTime = false

    /// The session's prompts, for a guided tool; empty for the others.
    private var script: PromptScript

    private let picker: PromptPicker
    /// When the timer last started running; `nil` until Play, and while paused.
    private var runningSince: Date?
    /// The time run before the last pause.
    private var elapsedBefore = Duration.zero
    /// The motion clock's counterparts, which Back 15 leaves alone.
    private var motionSince: Date?
    private var motionBefore = Duration.zero

    /// The prompts are chosen here, so a guided tool shows its first one from the moment it opens.
    init(tool: QuickTool, now: Date, picker: PromptPicker) {
        self.tool = tool
        self.picker = picker
        script = picker.script(for: tool)
        startIfPaged(now: now)
    }

    var isPaused: Bool {
        stage == .running && runningSince == nil
    }

    var length: Duration? {
        tool.length
    }

    /// How far through the run, from 0 to 1, for a timed tool's progress bar.
    var progress: Double {
        guard let length else { return 0 }
        return min(elapsed / length, 1)
    }

    /// The prompt for the stage the time is in, or `nil` for a tool without prompts.
    var prompt: ToolPrompt? {
        script.prompt(at: elapsed)
    }

    /// Every prompt of the session, in order.
    var prompts: [ToolPrompt] {
        script.prompts
    }

    /// After feeling heavier, a tool to try next, offered beside Get help: Breathe, or Get curious after Breathe.
    var suggestedTool: QuickTool? {
        guard feeling == .heavier else { return nil }
        return tool == .breathe ? .curious : .breathe
    }

    /// The time spent running as of `now`, without changing anything, for animations: smooth, stopping where it is
    /// on pause, and only ever moving forward, so Back 15 doesn't make anything jump.
    func motionTime(at now: Date) -> Duration {
        Self.time(before: motionBefore, since: motionSince, until: now)
    }

    /// Brings the timer up to `now`; the shell calls it a few times a second.
    func tick(now: Date) {
        advance(to: now)
        // Only a timed tool ends on time; a counted one runs on past its target until End.
        if tool.pacing == .timed, elapsed == length {
            finishedOnTime = true
            finish()
        }
    }

    func pause(now: Date) {
        advance(to: now)
        elapsedBefore = elapsed
        runningSince = nil
        motionBefore = motionTime(at: now)
        motionSince = nil
    }

    /// Leaving the app pauses the run, so it doesn't carry on unseen.
    func leaveApp(now: Date) {
        pause(now: now)
    }

    /// Coming back, a paged tool carries on by itself, having no Play to tap; the others wait for the person.
    func returnToApp(now: Date) {
        startIfPaged(now: now)
    }

    /// Play: starts the timer, or carries on after a pause. Only the person's Play uses up a session's prompt
    /// versions, not opening the tool, nor a paged tool starting by itself.
    func play(now: Date) {
        guard isPaused else { return }
        if !hasStarted {
            picker.countSession(of: tool)
        }
        run(from: now)
    }

    /// Back 15: the time moves back 15 seconds, never before the start, so a prompt missed can be read again. It
    /// works while paused, but not before the timer has started or once the run is over.
    func goBack(now: Date) {
        guard hasStarted, stage == .running else { return }
        advance(to: now)
        elapsed = max(elapsed - .seconds(15), .zero)
        elapsedBefore = elapsed
        if runningSince != nil {
            runningSince = now
        }
    }

    /// Opens `tool` fresh in place of the run that just finished.
    func start(_ tool: QuickTool, now: Date) {
        self.tool = tool
        script = picker.script(for: tool)
        stage = .running
        elapsed = .zero
        elapsedBefore = .zero
        motionBefore = .zero
        feeling = nil
        hasStarted = false
        finishedOnTime = false
        runningSince = nil
        motionSince = nil
        startIfPaged(now: now)
    }

    /// End: straight to the finish screen, keeping the time spent.
    func end(now: Date) {
        advance(to: now)
        finish()
    }

    func choose(_ feeling: Feeling) {
        self.feeling = feeling
    }

    /// Brings `elapsed` up to `now` while the timer runs, stopping a timed tool's at its length.
    private func advance(to now: Date) {
        guard runningSince != nil else { return }
        elapsed = Self.time(before: elapsedBefore, since: runningSince, until: now)
        if tool.pacing == .timed, let length {
            elapsed = min(elapsed, length)
        }
    }

    private func run(from now: Date) {
        guard isPaused else { return }
        hasStarted = true
        runningSince = now
        motionSince = now
    }

    private func startIfPaged(now: Date) {
        if tool.pacing == .paged {
            run(from: now)
        }
    }

    private func finish() {
        runningSince = nil
        motionSince = nil
        stage = .finished
    }

    /// `before`, plus the time from `since` to `now` if the clock is running.
    private static func time(before: Duration, since: Date?, until now: Date) -> Duration {
        guard let since else { return before }
        return before + .seconds(now.timeIntervalSince(since))
    }
}
