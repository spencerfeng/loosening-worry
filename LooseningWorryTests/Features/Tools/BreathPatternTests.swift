@testable import LooseningWorry
import Testing

struct BreathPatternTests {
    @Test
    func `a breath is 4 seconds in and 6 out`() {
        #expect(BreathPattern.inhale == .seconds(4))
        #expect(BreathPattern.exhale == .seconds(6))
        #expect(BreathPattern.cycle == .seconds(10))
    }

    @Test(arguments: [(Duration.seconds(60), 6), (.seconds(180), 18), (.seconds(300), 30)])
    func `a run's length holds a whole number of breaths`(length: Duration, breaths: Int) {
        #expect(BreathPattern.breaths(in: length) == breaths)
    }

    @Test(arguments: [
        (0.0, Breath.Phase.inhale, 0.0, 1),
        (2.0, .inhale, 0.5, 1),
        (4.0, .exhale, 0.0, 1),
        (7.0, .exhale, 0.5, 1),
        (10.0, .inhale, 0.0, 2),
        (21.0, .inhale, 0.25, 3),
        (25.0, .exhale, 1.0 / 6, 3),
    ])
    func `the breath at a moment says in or out, how far through, and which breath`(
        seconds: Double,
        phase: Breath.Phase,
        progress: Double,
        number: Int,
    ) {
        let breath = BreathPattern.breath(at: .seconds(seconds))

        #expect(breath.phase == phase)
        #expect(abs(breath.progress - progress) < 0.0001)
        #expect(breath.number == number)
    }

    @Test
    func `the circle is smallest as a breath begins, fullest at the turn, and smallest again as it ends`() {
        #expect(BreathPattern.size(at: .zero) == 0)
        #expect(BreathPattern.size(at: .seconds(4)) == 1)
        #expect(abs(BreathPattern.size(at: .seconds(9.999))) < 0.001)
        #expect(BreathPattern.size(at: .seconds(10)) == 0)
    }

    @Test
    func `the circle only grows on the in-breath and only shrinks on the out-breath`() {
        let inhale = stride(from: 0.0, through: 4.0, by: 0.25).map { BreathPattern.size(at: .seconds($0)) }
        let exhale = stride(from: 4.0, through: 10.0, by: 0.25).map { BreathPattern.size(at: .seconds($0)) }

        #expect(zip(inhale, inhale.dropFirst()).allSatisfy { $0 < $1 })
        #expect(zip(exhale.dropLast(), exhale.dropFirst().dropLast()).allSatisfy { $0 > $1 })
    }

    /// The vibration follows the circle, so someone can breathe along with their eyes closed.
    @Test
    func `the haptics swell to their strongest at the turn and fade to nothing by the next breath`() {
        let curve = BreathPattern.hapticCurve

        #expect(curve.first?.time == 0)
        #expect(curve.last?.time == 10)
        #expect(curve.last?.intensity == 0)
        #expect(zip(curve, curve.dropFirst()).allSatisfy { $0.time < $1.time })
        let peak = curve.max { $0.intensity < $1.intensity }
        #expect(peak?.time == 4)
        #expect(curve.allSatisfy { (0 ... 1).contains($0.intensity) })
    }

    /// Where the vibration starts, so it lines up with the circle.
    @Test(arguments: [(0.0, 0.0), (4.0, 4.0), (13.5, 3.5), (59.0, 9.0)])
    func `the offset is how far into the current breath a moment is`(seconds: Double, offset: Double) {
        #expect(abs(BreathPattern.offset(at: .seconds(seconds)) - offset) < 0.0001)
    }

    /// The end of the last breath is the end of the run, not the start of another.
    @Test
    func `a run's last moment is the end of its last breath`() {
        let breath = BreathPattern.breath(at: .seconds(60), of: 6)

        #expect(breath.number == 6)
        #expect(breath.phase == .exhale)
        #expect(breath.progress == 1)
        #expect(BreathPattern.breath(at: .seconds(25), of: 6) == BreathPattern.breath(at: .seconds(25)))
    }
}
