@testable import LooseningWorry
import Testing

struct LoopLapTests {
    /// Angles are clockwise from three o'clock, so the top of the ring is -90°.
    @Test(arguments: [(0.0, -90.0), (5.0 / 3, 30.0), (10.0 / 3, 150.0), (5.0, -90.0), (6.25, 0.0)])
    func `the dot sets off from the top and goes round once every five seconds`(
        elapsed: Double,
        angle: Double,
    ) {
        #expect(abs(LoopLap.dotAngle(after: elapsed) - angle) < 0.001)
    }

    @Test
    func `a stop pops most with the dot on it, and not at all once it's well past`() {
        #expect(LoopLap.scale(ofStopAt: 30, dotAngle: 30) == LoopLap.popScale)
        #expect(LoopLap.scale(ofStopAt: 30, dotAngle: 40) > 1)
        #expect(LoopLap.scale(ofStopAt: 30, dotAngle: 40) < LoopLap.popScale)
        #expect(LoopLap.scale(ofStopAt: 30, dotAngle: 90) == 1)
    }

    /// The top stop sits at -90°, which is also 270°: the dot arriving from the left still pops it.
    @Test
    func `the top stop pops as the dot comes round the end of the lap`() {
        #expect(LoopLap.scale(ofStopAt: -90, dotAngle: 265) > 1)
    }
}
