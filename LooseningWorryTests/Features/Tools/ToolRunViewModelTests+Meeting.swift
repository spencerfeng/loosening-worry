import Foundation
@testable import LooseningWorry
import Testing

/// A tool run from the logger's "Nothing yet, I'm in it now": the tool is how the person met the urge, so the run
/// saves a loop of its own.
extension ToolRunViewModelTests {
    @Test
    func `meeting the urge with a tool saves the loop as it ends, its result not sure yet`() throws {
        let model = model(.curious, meeting: OptionChoice(.work, label: "Work"))
        model.play(now: start)

        model.end(now: start.addingTimeInterval(40))

        let loop = try #require(sessions.sessions.only?.loop)
        #expect(loop.triggerID == "trigger.work")
        #expect(loop.triggerLabel == "Work")
        #expect(loop.behaviorID == "tool.curious")
        #expect(loop.behaviorLabel == "Got curious")
        #expect(loop.resultID == "result.notSure")
        #expect(loop.resultLabel == "Not sure")
        #expect(loop.noticed == .asItStarted)
    }

    @Test(arguments: [
        (ToolOutcome.lighter, "outcome.lighter", "Lighter"),
        (.same, "outcome.same", "About the same"),
        (.heavier, "outcome.heavier", "Heavier"),
    ])
    func `how it felt becomes the loop's result`(outcome: ToolOutcome, id: String, label: String) throws {
        let model = model(.breathe, meeting: OptionChoice(.work, label: "Work"))
        model.play(now: start)
        model.end(now: start.addingTimeInterval(40))

        model.choose(outcome)

        let loop = try #require(sessions.sessions.only?.loop)
        #expect(loop.resultID == id)
        #expect(loop.resultLabel == label)
    }

    /// The finish screen says the answer wasn't saved, so the loop mustn't claim it was.
    @Test
    func `if the answer can't be saved, the loop stays not sure`() throws {
        let model = model(.curious, meeting: OptionChoice(.work, label: "Work"))
        model.play(now: start)
        model.end(now: start.addingTimeInterval(40))
        sessions.failingOutcome = true

        model.choose(.lighter)

        let loop = try #require(sessions.sessions.only?.loop)
        #expect(loop.resultID == "result.notSure")
        #expect(model.saveFailure == .outcome)
    }

    /// Closing the tool, or ending it before starting, isn't meeting the urge, so there's no loop to save.
    @Test
    func `a run that never started saves no loop`() {
        let model = model(.curious, meeting: OptionChoice(.work, label: "Work"))

        model.end(now: start.addingTimeInterval(10))

        #expect(sessions.sessions.isEmpty)
    }

    /// One urge is one loop: another tool in the same sitting joins it, and how the person feels at the end is its
    /// result.
    @Test
    func `another tool in the same sitting joins the same loop`() throws {
        let model = model(.curious, meeting: OptionChoice(.work, label: "Work"))
        model.play(now: start)
        model.end(now: start.addingTimeInterval(40))
        model.choose(.heavier)

        model.start(.breathe, now: start.addingTimeInterval(50))
        model.play(now: start.addingTimeInterval(50))
        model.end(now: start.addingTimeInterval(110))
        model.choose(.lighter)

        let loops = sessions.sessions.map(\.loop)
        #expect(loops.count == 2)
        let loop = try #require(sessions.sessions.first?.loop)
        #expect(loops.allSatisfy { $0 === loop })
        #expect(loop.behaviorID == "tool.curious")
        #expect(loop.resultID == "outcome.lighter")
    }

    /// The finish screen and the logger go by whether a loop was saved, so a failed save mustn't claim one.
    @Test
    func `if the session can't be saved, no loop is claimed`() {
        let model = model(.curious, meeting: OptionChoice(.work, label: "Work"))
        sessions.failing = true
        model.play(now: start)

        model.end(now: start.addingTimeInterval(40))

        #expect(model.meetingLoop == nil)
        #expect(model.saveFailure == .session)
    }

    /// Nothing would be kept, so the finish screen doesn't ask; other runs ask as they always have.
    @Test
    func `a run from Nothing yet that saved nothing doesn't ask how it felt`() {
        let unsaved = model(.curious, meeting: OptionChoice(.work, label: "Work"))
        unsaved.end(now: start.addingTimeInterval(10))
        #expect(unsaved.asksHowItFelt == false)

        let saved = model(.curious, meeting: OptionChoice(.work, label: "Work"))
        saved.play(now: start)
        saved.end(now: start.addingTimeInterval(40))
        #expect(saved.asksHowItFelt)

        let plain = model(.curious)
        plain.end(now: start.addingTimeInterval(10))
        #expect(plain.asksHowItFelt)
    }

    @Test
    func `a run that ends on time saves the loop too`() {
        let model = model(.breathe, meeting: OptionChoice(.work, label: "Work"))
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(61))

        #expect(model.meetingLoop?.behaviorID == "tool.breathe")
    }
}
