import Foundation
@testable import LooseningWorry
import Testing

/// Breathe's part of the run: the length the person chooses, and which breath it's on.
extension ToolRunViewModelTests {
    @Test
    func `a Breathe run offers 1, 3 or 5 minutes and starts at 1`() {
        let model = model(.breathe)

        #expect(model.lengthOptions == [.seconds(60), .seconds(180), .seconds(300)])
        #expect(model.length == .seconds(60))
    }

    @Test(arguments: [QuickTool.curious, .noteIt, .beKind])
    func `the other tools have no length to choose`(tool: QuickTool) {
        let model = model(tool)

        #expect(model.lengthOptions.count <= 1)
    }

    @Test
    func `a length chosen before Play sets the run's length, and Breathe opens with it next time`() {
        let model = model(.breathe)

        model.chooseLength(.seconds(180))

        #expect(model.length == .seconds(180))
        #expect(self.model(.breathe).length == .seconds(180))
    }

    @Test
    func `a run ends on the length chosen`() {
        let model = model(.breathe)
        model.chooseLength(.seconds(180))
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(61))
        #expect(model.stage == .running)

        model.tick(now: start.addingTimeInterval(181))
        #expect(model.stage == .finished)
        #expect(model.elapsed == .seconds(180))
    }

    /// Once breathing has begun, the length stays as it started; and only the lengths offered can be chosen.
    @Test
    func `the length can't change once started, nor be one not offered`() {
        let model = model(.breathe)
        model.chooseLength(.seconds(90))
        #expect(model.length == .seconds(60))

        model.play(now: start)
        model.chooseLength(.seconds(300))
        #expect(model.length == .seconds(60))
    }

    @Test
    func `a Breathe run counts its breaths out of the length chosen, stopping at the last`() {
        let model = model(.breathe)
        #expect(model.breath?.number == 1)
        #expect(model.breathCount == 6)

        model.chooseLength(.seconds(180))
        model.play(now: start)
        model.tick(now: start.addingTimeInterval(25))
        #expect(model.breath?.number == 3)
        #expect(model.breathCount == 18)

        model.tick(now: start.addingTimeInterval(180))
        #expect(model.breath?.number == 18)
    }

    @Test
    func `only Breathe counts breaths`() {
        let model = model(.curious)

        #expect(model.breath == nil)
        #expect(model.breathCount == 0)
    }

    @Test
    func `a Breathe run opened again from the finish screen keeps the length chosen`() {
        let model = model(.breathe)
        model.chooseLength(.seconds(180))
        model.play(now: start)
        model.end(now: start.addingTimeInterval(20))

        model.start(.breathe, now: start.addingTimeInterval(30))

        #expect(model.length == .seconds(180))
        #expect(model.breathCount == 18)
    }
}
