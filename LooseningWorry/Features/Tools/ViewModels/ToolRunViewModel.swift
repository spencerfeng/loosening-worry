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

    /// When the timer last started running; `nil` until Play, and while paused.
    private var runningSince: Date?
    /// The time run before the last pause.
    private var elapsedBefore = Duration.zero

    init(tool: QuickTool, now: Date) {
        self.tool = tool
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

    /// After feeling heavier, a tool to try next, offered beside Get help: Breathe, or Get curious after Breathe.
    var suggestedTool: QuickTool? {
        guard feeling == .heavier else { return nil }
        return tool == .breathe ? .curious : .breathe
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
    }

    /// Leaving the app pauses the run, so it doesn't carry on unseen.
    func leaveApp(now: Date) {
        pause(now: now)
    }

    /// Coming back, a paged tool carries on by itself, having no Play to tap; the others wait for the person.
    func returnToApp(now: Date) {
        startIfPaged(now: now)
    }

    /// Starts the timer, or carries on after a pause.
    func play(now: Date) {
        guard isPaused else { return }
        hasStarted = true
        runningSince = now
    }

    /// Opens `tool` fresh in place of the run that just finished.
    func start(_ tool: QuickTool, now: Date) {
        self.tool = tool
        stage = .running
        elapsed = .zero
        elapsedBefore = .zero
        feeling = nil
        hasStarted = false
        finishedOnTime = false
        runningSince = nil
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
        guard let runningSince else { return }
        elapsed = elapsedBefore + .seconds(now.timeIntervalSince(runningSince))
        if tool.pacing == .timed, let length {
            elapsed = min(elapsed, length)
        }
    }

    private func startIfPaged(now: Date) {
        if tool.pacing == .paged {
            play(now: now)
        }
    }

    private func finish() {
        runningSince = nil
        stage = .finished
    }
}
