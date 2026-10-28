import Foundation
@testable import LooseningWorry
import Testing

@MainActor
final class ToolRunViewModelTests {
    let start = Date(timeIntervalSince1970: 1_793_000_000)
    /// Each test gets its own defaults for the prompt rotation, so nothing leaks between tests or into the app.
    private let suiteName = "ToolRunViewModelTests.\(UUID().uuidString)"
    private let picker: PromptPicker
    private let lengths: ToolLengths
    let sessions = FakeSessionRecorder()

    init() throws {
        // Its own prompts, so the tests don't depend on how a reviewer arranges the bundled file. Be kind has some
        // too, to check that a tool which starts by itself doesn't use up a session.
        let prompts = try ToolPrompts(json: Data("""
        {
          "curious": [
            { "id": "find", "seconds": 30, "prompts": ["curious.find.1", "curious.find.2"] },
            { "id": "curious", "seconds": 30, "prompts": ["curious.curious.1", "curious.curious.2"] },
            { "id": "watch", "seconds": 30, "prompts": ["curious.watch.1", "curious.watch.2"] }
          ],
          "beKind": [
            { "id": "page", "seconds": 30, "prompts": ["curious.find.1", "curious.find.2"] }
          ]
        }
        """.utf8))
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        picker = PromptPicker(defaults: defaults, prompts: prompts)
        lengths = ToolLengths(defaults: defaults)
    }

    /// A run of `tool` opened at the start, with the tests' own prompts and stored lengths.
    func model(_ tool: QuickTool, loop: Loop? = nil) -> ToolRunViewModel {
        ToolRunViewModel(tool: tool, now: start, picker: picker, lengths: lengths, sessions: sessions, loop: loop)
    }

    isolated deinit {
        picker.defaults.removePersistentDomain(forName: suiteName)
    }

    @Test(arguments: [
        (QuickTool.curious, Duration.seconds(90)),
        (.breathe, .seconds(60)),
        (.noteIt, .seconds(90)),
    ])
    func `a tool opens ready but stopped, with nothing elapsed, for its own length`(tool: QuickTool, length: Duration) {
        let model = model(tool)

        #expect(model.tool == tool)
        #expect(model.length == length)
        #expect(model.elapsed == .zero)
        #expect(model.progress == 0)
        #expect(model.stage == .running)
        #expect(model.isPaused)
        #expect(model.hasStarted == false)
    }

    /// The person starts the timer when they're ready, not when the tool opens.
    @Test
    func `the timer waits for Play`() {
        let model = model(.curious)

        model.tick(now: start.addingTimeInterval(30))
        #expect(model.elapsed == .zero)

        model.play(now: start.addingTimeInterval(30))
        model.tick(now: start.addingTimeInterval(36))
        #expect(model.hasStarted)
        #expect(model.isPaused == false)
        #expect(model.elapsed == .seconds(6))
    }

    @Test
    func `as time passes, the timer and the progress bar move`() {
        let model = model(.curious)
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(36))

        #expect(model.elapsed == .seconds(36))
        #expect(model.progress == 0.4)
    }

    @Test
    func `pausing stops the timer, and resuming carries on from where it was`() {
        let model = model(.curious)
        model.play(now: start)

        model.pause(now: start.addingTimeInterval(10))
        model.tick(now: start.addingTimeInterval(40))
        #expect(model.isPaused)
        #expect(model.elapsed == .seconds(10))

        model.play(now: start.addingTimeInterval(40))
        model.tick(now: start.addingTimeInterval(45))
        #expect(model.isPaused == false)
        #expect(model.elapsed == .seconds(15))
    }

    @Test
    func `when the time is up, the run moves to the finish screen and the timer stops at the length`() {
        let model = model(.breathe)
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(59))
        #expect(model.stage == .running)

        model.tick(now: start.addingTimeInterval(61))
        #expect(model.stage == .finished)
        #expect(model.finishedOnTime)
        #expect(model.elapsed == .seconds(60))
        #expect(model.progress == 1)

        model.tick(now: start.addingTimeInterval(90))
        #expect(model.elapsed == .seconds(60))
    }

    @Test
    func `ending early moves to the finish screen and keeps the time spent`() {
        let model = model(.curious)
        model.play(now: start)

        model.end(now: start.addingTimeInterval(20))
        model.tick(now: start.addingTimeInterval(50))

        #expect(model.stage == .finished)
        #expect(model.elapsed == .seconds(20))
    }

    @Test
    func `the finish screen starts with no answer, and the answer can be changed`() {
        let model = model(.curious)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))
        #expect(model.feeling == nil)

        model.choose(.lighter)
        model.choose(.same)

        #expect(model.feeling == .same)
    }

    @Test(arguments: [
        (QuickTool.curious, QuickTool.breathe),
        (.noteIt, .breathe),
        (.beKind, .breathe),
        (.breathe, .curious),
    ])
    func `feeling heavier suggests Breathe, or Get curious after Breathe`(tool: QuickTool, suggested: QuickTool) {
        let model = model(tool)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        model.choose(.heavier)

        #expect(model.suggestedTool == suggested)
    }

    @Test(arguments: [Feeling?.none, .lighter, .same])
    func `only feeling heavier suggests another tool`(feeling: Feeling?) {
        let model = model(.curious)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        if let feeling {
            model.choose(feeling)
        }

        #expect(model.suggestedTool == nil)
    }

    @Test
    func `another tool from the finish screen opens fresh, waiting for Play`() {
        let model = model(.curious)
        model.play(now: start)
        model.pause(now: start.addingTimeInterval(10))
        model.end(now: start.addingTimeInterval(20))
        model.choose(.heavier)
        let later = start.addingTimeInterval(100)

        model.start(.breathe, now: later)
        model.tick(now: later)
        #expect(model.tool == .breathe)
        #expect(model.stage == .running)
        #expect(model.hasStarted == false)
        #expect(model.elapsed == .zero)
        #expect(model.feeling == nil)

        model.play(now: later)
        model.tick(now: later.addingTimeInterval(5))
        #expect(model.elapsed == .seconds(5))
    }

    /// A finished run stays finished, whatever plays it again, such as coming back to the app.
    @Test
    func `a finished run can't be played again`() {
        let model = model(.curious)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(20))

        model.play(now: start.addingTimeInterval(30))
        model.tick(now: start.addingTimeInterval(40))

        #expect(model.stage == .finished)
        #expect(model.elapsed == .seconds(20))
    }

    /// Note it counts the time from the first word tapped; 1:30 is a target, not a limit.
    @Test
    func `a Note it timer runs past its length until the person ends it`() {
        let model = model(.noteIt)
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(100))

        #expect(model.stage == .running)
        #expect(model.elapsed == .seconds(100))
    }

    /// Be kind goes at the person's own pace through its pages, so it has no length and no Play.
    @Test
    func `a Be kind run starts the moment it opens and never finishes on time`() {
        let model = model(.beKind)

        model.tick(now: start.addingTimeInterval(200))

        #expect(model.length == nil)
        #expect(model.hasStarted)
        #expect(model.stage == .running)
        #expect(model.elapsed == .seconds(200))
    }

    @Test
    func `a Be kind run opened from the finish screen starts straight away`() {
        let model = model(.curious)
        model.end(now: start.addingTimeInterval(20))
        let later = start.addingTimeInterval(100)

        model.start(.beKind, now: later)
        model.tick(now: later.addingTimeInterval(5))

        #expect(model.elapsed == .seconds(5))
    }

    /// Leaving the app pauses every tool; coming back carries on only where there's no Play to tap.
    @Test(arguments: [(QuickTool.curious, true), (.breathe, true), (.noteIt, true), (.beKind, false)])
    func `after leaving the app, only Be kind carries on by itself`(tool: QuickTool, staysPaused: Bool) {
        let model = model(tool)
        model.play(now: start)

        model.leaveApp(now: start.addingTimeInterval(10))
        model.returnToApp(now: start.addingTimeInterval(60))
        model.tick(now: start.addingTimeInterval(65))

        #expect(model.isPaused == staysPaused)
        #expect(model.elapsed == (staysPaused ? .seconds(10) : .seconds(15)))
    }

    /// Only running out of time counts as finishing on time; End is the person's own doing, even at the last second.
    @Test(arguments: [59.0, 60.0, 75.0])
    func `ending is never finishing on time`(endsAt seconds: Double) {
        let model = model(.breathe)
        model.play(now: start)

        model.end(now: start.addingTimeInterval(seconds))

        #expect(model.stage == .finished)
        #expect(model.finishedOnTime == false)
    }

    @Test
    func `another tool from the finish screen hasn't finished on time`() {
        let model = model(.breathe)
        model.play(now: start)
        model.tick(now: start.addingTimeInterval(60))

        model.start(.curious, now: start.addingTimeInterval(70))

        #expect(model.finishedOnTime == false)
    }

    @Test
    func `a Be kind run has no progress bar to fill and ends on End with the time spent`() {
        let model = model(.beKind)

        model.tick(now: start.addingTimeInterval(40))
        #expect(model.progress == 0)

        model.end(now: start.addingTimeInterval(45))
        #expect(model.stage == .finished)
        #expect(model.elapsed == .seconds(45))
        #expect(model.finishedOnTime == false)
    }
}

/// Get curious's part of the run: its prompts, Back 15 and the motion clock.
extension ToolRunViewModelTests {
    @Test
    func `back 15 moves the time back and carries on from there`() {
        let model = model(.curious)
        model.play(now: start)

        model.goBack(now: start.addingTimeInterval(40))
        #expect(model.elapsed == .seconds(25))

        model.tick(now: start.addingTimeInterval(45))
        #expect(model.elapsed == .seconds(30))
    }

    @Test
    func `back 15 never goes below the start`() {
        let model = model(.curious)
        model.play(now: start)

        model.goBack(now: start.addingTimeInterval(10))

        #expect(model.elapsed == .zero)
    }

    @Test
    func `back 15 works while paused, and the run stays paused`() {
        let model = model(.curious)
        model.play(now: start)
        model.pause(now: start.addingTimeInterval(40))

        model.goBack(now: start.addingTimeInterval(50))
        model.tick(now: start.addingTimeInterval(60))
        #expect(model.isPaused)
        #expect(model.elapsed == .seconds(25))

        model.play(now: start.addingTimeInterval(60))
        model.tick(now: start.addingTimeInterval(65))
        #expect(model.elapsed == .seconds(30))
    }

    @Test
    func `back 15 does nothing before Play or after the run is over`() {
        let model = model(.curious)
        model.goBack(now: start.addingTimeInterval(10))
        #expect(model.hasStarted == false)
        #expect(model.elapsed == .zero)

        model.play(now: start)
        model.end(now: start.addingTimeInterval(40))
        model.goBack(now: start.addingTimeInterval(45))
        #expect(model.stage == .finished)
        #expect(model.elapsed == .seconds(40))
    }

    /// The prompt is there from the first frame, so nothing shifts as the tool opens.
    @Test
    func `a Get curious run shows its first prompt as soon as it opens`() {
        let model = model(.curious)

        #expect(model.prompt?.id == "curious.find.1")
    }

    @Test
    func `the prompt follows the time`() {
        let model = model(.curious)
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(35))

        #expect(model.prompt?.id == "curious.curious.1")
    }

    /// Opening a tool and closing it without starting doesn't use up the session's wording.
    @Test
    func `a session counts once started, so the next run gets the next versions`() {
        _ = model(.curious)
        let opened = model(.curious)
        #expect(opened.prompt?.id == "curious.find.1")

        opened.play(now: start)
        opened.pause(now: start.addingTimeInterval(5))
        opened.play(now: start.addingTimeInterval(6))

        #expect(model(.curious).prompt?
            .id == "curious.find.2")
    }

    @Test
    func `a Get curious run opened again from the finish screen gets the next versions`() {
        let model = model(.curious)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        model.start(.curious, now: start.addingTimeInterval(40))

        #expect(model.prompt?.id == "curious.find.2")
    }

    @Test
    func `a tool with no prompts in the file shows none`() {
        let model = model(.breathe)

        #expect(model.prompt == nil)
    }

    /// Animations follow a clock of the time spent running, so they stop where they are on pause, carry on from
    /// there, and don't jump back when Back 15 moves the timer.
    @Test
    func `the motion clock counts only time spent running, and Back 15 doesn't rewind it`() {
        let model = model(.curious)
        #expect(model.motionTime(at: start.addingTimeInterval(5)) == .zero)

        model.play(now: start)
        #expect(model.motionTime(at: start.addingTimeInterval(10.5)) == .seconds(10.5))

        model.pause(now: start.addingTimeInterval(12))
        #expect(model.motionTime(at: start.addingTimeInterval(30)) == .seconds(12))

        model.play(now: start.addingTimeInterval(30))
        model.goBack(now: start.addingTimeInterval(40))
        #expect(model.elapsed == .seconds(7))
        #expect(model.motionTime(at: start.addingTimeInterval(43)) == .seconds(25))
    }

    /// A paged tool starts by itself, and its view can be rebuilt many times, so only Play uses up a session.
    @Test
    func `opening a tool that starts by itself doesn't use up a session`() {
        let opened = model(.beKind)
        #expect(opened.hasStarted)

        let next = model(.beKind)

        #expect(next.prompt?.id == "curious.find.1")
    }
}
