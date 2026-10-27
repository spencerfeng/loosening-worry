import Foundation
@testable import LooseningWorry
import Testing

@MainActor
struct ToolRunViewModelTests {
    private let start = Date(timeIntervalSince1970: 1_793_000_000)

    @Test(arguments: [
        (QuickTool.curious, Duration.seconds(90)),
        (.breathe, .seconds(60)),
        (.noteIt, .seconds(90)),
    ])
    func `a tool opens ready but stopped, with nothing elapsed, for its own length`(tool: QuickTool, length: Duration) {
        let model = ToolRunViewModel(tool: tool, now: start)

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
        let model = ToolRunViewModel(tool: .curious, now: start)

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
        let model = ToolRunViewModel(tool: .curious, now: start)
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(36))

        #expect(model.elapsed == .seconds(36))
        #expect(model.progress == 0.4)
    }

    @Test
    func `pausing stops the timer, and resuming carries on from where it was`() {
        let model = ToolRunViewModel(tool: .curious, now: start)
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
        let model = ToolRunViewModel(tool: .breathe, now: start)
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
        let model = ToolRunViewModel(tool: .curious, now: start)
        model.play(now: start)

        model.end(now: start.addingTimeInterval(20))
        model.tick(now: start.addingTimeInterval(50))

        #expect(model.stage == .finished)
        #expect(model.elapsed == .seconds(20))
    }

    @Test
    func `the finish screen starts with no answer, and the answer can be changed`() {
        let model = ToolRunViewModel(tool: .curious, now: start)
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
        let model = ToolRunViewModel(tool: tool, now: start)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        model.choose(.heavier)

        #expect(model.suggestedTool == suggested)
    }

    @Test(arguments: [Feeling?.none, .lighter, .same])
    func `only feeling heavier suggests another tool`(feeling: Feeling?) {
        let model = ToolRunViewModel(tool: .curious, now: start)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        if let feeling {
            model.choose(feeling)
        }

        #expect(model.suggestedTool == nil)
    }

    @Test
    func `another tool from the finish screen opens fresh, waiting for Play`() {
        let model = ToolRunViewModel(tool: .curious, now: start)
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
        let model = ToolRunViewModel(tool: .curious, now: start)
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
        let model = ToolRunViewModel(tool: .noteIt, now: start)
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(100))

        #expect(model.stage == .running)
        #expect(model.elapsed == .seconds(100))
    }

    /// Be kind goes at the person's own pace through its pages, so it has no length and no Play.
    @Test
    func `a Be kind run starts the moment it opens and never finishes on time`() {
        let model = ToolRunViewModel(tool: .beKind, now: start)

        model.tick(now: start.addingTimeInterval(200))

        #expect(model.length == nil)
        #expect(model.hasStarted)
        #expect(model.stage == .running)
        #expect(model.elapsed == .seconds(200))
    }

    @Test
    func `a Be kind run opened from the finish screen starts straight away`() {
        let model = ToolRunViewModel(tool: .curious, now: start)
        model.end(now: start.addingTimeInterval(20))
        let later = start.addingTimeInterval(100)

        model.start(.beKind, now: later)
        model.tick(now: later.addingTimeInterval(5))

        #expect(model.elapsed == .seconds(5))
    }

    /// Leaving the app pauses every tool; coming back carries on only where there's no Play to tap.
    @Test(arguments: [(QuickTool.curious, true), (.breathe, true), (.noteIt, true), (.beKind, false)])
    func `after leaving the app, only Be kind carries on by itself`(tool: QuickTool, staysPaused: Bool) {
        let model = ToolRunViewModel(tool: tool, now: start)
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
        let model = ToolRunViewModel(tool: .breathe, now: start)
        model.play(now: start)

        model.end(now: start.addingTimeInterval(seconds))

        #expect(model.stage == .finished)
        #expect(model.finishedOnTime == false)
    }

    @Test
    func `another tool from the finish screen hasn't finished on time`() {
        let model = ToolRunViewModel(tool: .breathe, now: start)
        model.play(now: start)
        model.tick(now: start.addingTimeInterval(60))

        model.start(.curious, now: start.addingTimeInterval(70))

        #expect(model.finishedOnTime == false)
    }

    @Test
    func `a Be kind run has no progress bar to fill and ends on End with the time spent`() {
        let model = ToolRunViewModel(tool: .beKind, now: start)

        model.tick(now: start.addingTimeInterval(40))
        #expect(model.progress == 0)

        model.end(now: start.addingTimeInterval(45))
        #expect(model.stage == .finished)
        #expect(model.elapsed == .seconds(45))
        #expect(model.finishedOnTime == false)
    }
}
