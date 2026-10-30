import Foundation
import Observation
import os

/// One run of a tool in the shared shell: its timer, then the finish screen's "How do you feel now?". The person
/// starts the timer, with Play or a tool's first tap, except in a paged tool, whose time runs from when it opens.
@Observable @MainActor
final class ToolRunViewModel {
    enum Stage {
        case running, finished
    }

    /// What couldn't be saved, for the finish screen to say.
    enum SaveFailure {
        case session, feeling
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
    /// How long the run is meant to last: the tool's own, or the one the person chose. A paged tool has none.
    private(set) var length: Duration?
    /// The session, or the answer given on the finish screen, couldn't be saved; the finish screen says which.
    private(set) var saveFailure: SaveFailure?

    /// The session's prompts, for a guided tool; empty for the others.
    private var script: PromptScript

    private let picker: PromptPicker
    private let lengths: ToolLengths
    private let sessions: any SessionRecording
    /// The loop just logged, for a tool started from Nice catch.
    private let loop: Loop?
    /// When the run started: on Play or the first tap, or for a paged tool, when it opened.
    private var startedAt: Date?
    /// Whether the person has engaged with a paged tool, which runs from the moment it opens; only then is it a
    /// session.
    private var hasEngaged = false
    /// The run saved as it ended, which the feeling is saved with.
    private var session: ToolSession?
    /// When the timer last started running; `nil` until Play, and while paused.
    private var runningSince: Date?
    /// The time run before the last pause.
    private var elapsedBefore = Duration.zero
    /// The motion clock's counterparts, which Back 15 leaves alone.
    private var motionSince: Date?
    private var motionBefore = Duration.zero
    /// This tool's feelings from before this run, read as it finishes.
    private var earlierFeelings: [Feeling] = []

    /// The prompts are chosen here, so a guided tool shows its first one from the moment it opens.
    init(
        tool: QuickTool,
        now: Date,
        picker: PromptPicker,
        lengths: ToolLengths,
        sessions: any SessionRecording,
        loop: Loop? = nil,
    ) {
        self.tool = tool
        self.picker = picker
        self.lengths = lengths
        self.sessions = sessions
        self.loop = loop
        script = picker.script(for: tool)
        length = lengths.length(for: tool)
        startIfPaged(now: now)
    }

    var isPaused: Bool {
        stage == .running && runningSince == nil
    }

    /// The lengths the person can choose between before starting; one or none means there's no choice.
    var lengthOptions: [Duration] {
        tool.lengthOptions
    }

    /// Where the breathing is, for Breathe; `nil` for the other tools.
    var breath: Breath? {
        guard tool == .breathe else { return nil }
        return BreathPattern.breath(at: elapsed, of: breathCount)
    }

    /// How many breaths the run holds, for Breathe's "Breath 3 of 18".
    var breathCount: Int {
        guard tool == .breathe, let length else { return 0 }
        return BreathPattern.breaths(in: length)
    }

    /// Whether a counted tool has run past its target length, which it carries on past until End.
    var isPastLength: Bool {
        guard let length else { return false }
        return elapsed > length
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

    /// How often this tool has left the person lighter, counting the answer showing now. A run that wasn't saved
    /// isn't counted, as it won't be there to count next time.
    var lighterTally: LighterTally? {
        guard let feeling, session != nil else { return nil }
        return LighterTally(feelings: earlierFeelings + [feeling])
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
        let unclamped = Self.time(before: elapsedBefore, since: runningSince, until: now)
        advance(to: now)
        // Only a timed tool ends on time; a counted one runs on past its target until End.
        if tool.pacing == .timed, let length, elapsed == length {
            finishedOnTime = true
            // At the moment the time ran out, not the tick that noticed it a little later.
            let overshoot = max(unclamped - length, .zero) / .seconds(1)
            finish(now: now.addingTimeInterval(-overshoot))
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

    /// Chooses how long the run lasts. Only before it starts, and only a length the tool offers; it's remembered for
    /// next time.
    func chooseLength(_ length: Duration) {
        guard !hasStarted, lengthOptions.contains(length) else { return }
        self.length = length
        lengths.remember(length, for: tool)
    }

    /// Opens `tool` fresh in place of the run that just finished.
    func start(_ tool: QuickTool, now: Date) {
        self.tool = tool
        script = picker.script(for: tool)
        length = lengths.length(for: tool)
        stage = .running
        elapsed = .zero
        elapsedBefore = .zero
        motionBefore = .zero
        feeling = nil
        hasStarted = false
        finishedOnTime = false
        hasEngaged = false
        startedAt = nil
        session = nil
        saveFailure = nil
        runningSince = nil
        motionSince = nil
        startIfPaged(now: now)
    }

    /// End: straight to the finish screen, keeping the time spent.
    func end(now: Date) {
        advance(to: now)
        finish(now: now)
    }

    /// The answer to "How do you feel now?", saved with the session.
    func choose(_ feeling: Feeling) {
        self.feeling = feeling
        guard let session else { return }
        do {
            try sessions.setFeeling(feeling, on: session)
        } catch {
            Self.logger.error("Couldn't save the feeling with the session: \(error)")
            saveFailure = .feeling
        }
    }

    /// A paged tool has no Play, so it tells the run when the person has engaged, such as turning past the first page.
    func markEngaged() {
        hasEngaged = true
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
        if startedAt == nil {
            startedAt = now
        }
        hasStarted = true
        runningSince = now
        motionSince = now
    }

    private func startIfPaged(now: Date) {
        if tool.pacing == .paged {
            run(from: now)
        }
    }

    /// Once only: finishing again would read back the answer just saved as an earlier one.
    private func finish(now: Date) {
        guard stage == .running else { return }
        readEarlierFeelings()
        record(now: now)
        runningSince = nil
        motionSince = nil
        stage = .finished
    }

    /// Read before this run is saved, so its own answer is counted only once.
    private func readEarlierFeelings() {
        do {
            earlierFeelings = try sessions.feelings(for: tool)
        } catch {
            Self.logger.error("Couldn't read the tool's earlier feelings: \(error)")
            earlierFeelings = []
        }
    }

    /// Saves the run as a session once it has really started: Play or a first tap, or for a paged tool, the person
    /// engaging. A run ended before then isn't one.
    ///
    /// It lasts the time actually spent running, which Back 15 doesn't take away from. Every tool of a sitting
    /// started from Nice catch belongs to its loop, as the person's response to it.
    private func record(now: Date) {
        let isSession = tool.pacing == .paged ? hasEngaged : hasStarted
        guard isSession, session == nil, let startedAt else { return }
        do {
            session = try sessions.record(tool, startedAt: startedAt, duration: motionTime(at: now), loop: loop)
        } catch {
            Self.logger.error("Couldn't save the session: \(error)")
            saveFailure = .session
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Tools")

    /// `before`, plus the time from `since` to `now` if the clock is running.
    private static func time(before: Duration, since: Date?, until now: Date) -> Duration {
        guard let since else { return before }
        return before + .seconds(now.timeIntervalSince(since))
    }
}
