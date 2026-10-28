import Foundation

/// Breathe's pace: in for 4 seconds, out for 6. The longer out-breath is what calms; the pace is fixed, and the
/// screen tells anyone it doesn't suit to breathe naturally and watch the circle.
enum BreathPattern {
    static let inhale = Duration.seconds(4)
    static let exhale = Duration.seconds(6)
    static let cycle = inhale + exhale

    /// Where the breathing is `time` into a run.
    static func breath(at time: Duration) -> Breath {
        let cycles = max(time, .zero) / cycle
        let number = Int(cycles.rounded(.down))
        let into = cycle * (cycles - Double(number))
        return into < inhale
            ? Breath(phase: .inhale, progress: into / inhale, number: number + 1)
            : Breath(phase: .exhale, progress: (into - inhale) / exhale, number: number + 1)
    }

    /// Where the breathing is `time` into a run of `count` breaths: as `breath(at:)`, except that the run's last moment
    /// is the end of its last breath, not the start of another.
    static func breath(at time: Duration, of count: Int) -> Breath {
        guard time >= cycle * count else { return breath(at: time) }
        return Breath(phase: .exhale, progress: 1, number: count)
    }

    /// How far into the current breath `time` is, in seconds: where the vibration starts so it lines up.
    static func offset(at time: Duration) -> TimeInterval {
        let breath = breath(at: time)
        let start = breath.phase == .inhale ? Duration.zero : inhale
        let length = breath.phase == .inhale ? inhale : exhale
        return (start + length * breath.progress) / .seconds(1)
    }

    /// How full the circle is `time` into a run, from 0 to 1: it eases full over the in-breath and empty over the
    /// out-breath, slowest at the turns, as breathing is.
    static func size(at time: Duration) -> Double {
        let breath = breath(at: time)
        let eased = (1 - cos(.pi * breath.progress)) / 2
        return breath.phase == .inhale ? eased : 1 - eased
    }

    /// One breath of the vibration that guides it: faint as the in-breath begins, strongest at the turn, then fading
    /// to nothing over the out-breath. Points in seconds from the breath's start, with intensity from 0 to 1, drawn
    /// as a smooth curve between them.
    static let hapticCurve: [(time: TimeInterval, intensity: Float)] = [
        (0, 0.1), (2, 0.35), (4, 0.6), (7, 0.25), (10, 0),
    ]

    /// How many breaths fit in `length`; every length offered is a whole number of them.
    static func breaths(in length: Duration) -> Int {
        Int(length / cycle)
    }
}

/// A moment in the breathing.
struct Breath: Equatable {
    enum Phase {
        case inhale, exhale
    }

    let phase: Phase
    /// How far through the phase, from 0 to 1.
    let progress: Double
    /// Which breath of the run, counting from 1.
    let number: Int
}
