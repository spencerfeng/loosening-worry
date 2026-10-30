import Foundation
@testable import LooseningWorry
import Testing

/// The finish screen's "Get curious has left you lighter 5 of 7 times".
extension ToolRunViewModelTests {
    /// A finished run of `tool`, waiting for its answer.
    func finishedRun(_ tool: QuickTool) -> ToolRunViewModel {
        let model = model(tool)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))
        return model
    }

    /// Earlier answers count, and so does the one just given.
    @Test
    func `answering counts how often the tool has left the person lighter`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .same, .lighter])
        let model = finishedRun(.curious)

        model.choose(.lighter)

        #expect(model.lighterTally == LighterTally(lighter: 3, answered: 4))
    }

    /// Shown after the answer, so it can't sway it.
    @Test
    func `there's no tally before the person answers`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .lighter, .lighter])

        #expect(finishedRun(.curious).lighterTally == nil)
    }

    /// "1 of 1 times" says nothing yet.
    @Test(arguments: [0, 1])
    func `the tally waits for three answered runs`(earlier: Int) {
        sessions.saveEarlier(.curious, feelings: Array(repeating: .lighter, count: earlier))
        let model = finishedRun(.curious)

        model.choose(.lighter)

        #expect(model.lighterTally == nil)
    }

    /// It's there to encourage; a low count could read as doing it wrong, and the screen already offers other tools.
    @Test
    func `there's no tally when fewer than half the answers were lighter`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .same, .heavier])
        let model = finishedRun(.curious)

        model.choose(.same)

        #expect(model.lighterTally == nil)
    }

    @Test
    func `half the answers lighter is enough`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .same, .lighter])
        let model = finishedRun(.curious)

        model.choose(.heavier)

        #expect(model.lighterTally == LighterTally(lighter: 2, answered: 4))
    }

    /// It counts the answer showing now, once, however often it's changed.
    @Test
    func `changing the answer changes the tally`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .same, .lighter])
        let model = finishedRun(.curious)
        model.choose(.lighter)

        model.choose(.same)

        #expect(model.lighterTally == LighterTally(lighter: 2, answered: 4))
    }

    @Test
    func `another tool from the finish screen counts its own answers`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .lighter, .lighter])
        sessions.saveEarlier(.breathe, feelings: [.lighter, .same])
        let model = finishedRun(.curious)
        model.choose(.lighter)

        model.start(.breathe, now: start.addingTimeInterval(40))
        model.play(now: start.addingTimeInterval(40))
        model.end(now: start.addingTimeInterval(70))
        model.choose(.lighter)

        #expect(model.lighterTally == LighterTally(lighter: 2, answered: 3))
    }

    /// Next time it wouldn't be there to count, so the totals would disagree.
    @Test
    func `a run that wasn't saved isn't counted`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .lighter, .lighter])
        sessions.failing = true
        let model = finishedRun(.curious)

        model.choose(.lighter)

        #expect(model.lighterTally == nil)
    }

    /// Ended before Play, it isn't a session, though the finish screen still asks.
    @Test
    func `a run ended before it started isn't counted`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .lighter, .lighter])
        let model = model(.curious)
        model.end(now: start.addingTimeInterval(10))

        model.choose(.lighter)

        #expect(model.lighterTally == nil)
    }

    /// A late tick mustn't finish the run again, reading back the answer just saved and counting it twice.
    @Test
    func `a tick after a timed run ends doesn't count its answer twice`() {
        sessions.saveEarlier(.breathe, feelings: [.lighter, .lighter])
        let model = model(.breathe)
        model.play(now: start)
        model.tick(now: start.addingTimeInterval(61))
        model.choose(.lighter)

        model.tick(now: start.addingTimeInterval(62))

        #expect(model.lighterTally == LighterTally(lighter: 3, answered: 3))
    }

    /// The rest of the finish screen works as ever.
    @Test
    func `there's no tally when the earlier feelings can't be read`() {
        sessions.saveEarlier(.curious, feelings: [.lighter, .lighter, .lighter])
        sessions.failingReads = true
        let model = finishedRun(.curious)

        model.choose(.lighter)

        #expect(model.lighterTally == nil)
    }
}
