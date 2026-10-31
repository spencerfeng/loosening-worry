import Foundation

/// Onboarding's loop in motion: a dot goes round the ring, and each stop pops as the dot reaches it, acting out
/// sets you off, then you do, then it gives you, and round again. Angles are clockwise from three o'clock.
enum LoopLap {
    /// Seconds for one lap.
    static let duration = 5.0
    /// How big a stop grows with the dot right on it.
    static let popScale = 1.12
    /// How far either side of a stop, in degrees, the dot starts to make it grow.
    private static let reach = 25.0

    /// Where the dot is `elapsed` seconds in. It sets off from the top, where the loop starts.
    static func dotAngle(after elapsed: TimeInterval) -> Double {
        let lap = elapsed.truncatingRemainder(dividingBy: duration) / duration
        return -90 + 360 * lap
    }

    /// How big the stop at `stopAngle` is with the dot at `dotAngle`: easing up to `popScale` as the dot arrives and
    /// back down as it leaves.
    static func scale(ofStopAt stopAngle: Double, dotAngle: Double) -> Double {
        let apart = abs((dotAngle - stopAngle).truncatingRemainder(dividingBy: 360))
        let distance = min(apart, 360 - apart)
        let nearness = max(0, 1 - distance / reach)
        let eased = nearness * nearness * (3 - 2 * nearness)
        return 1 + (popScale - 1) * eased
    }
}
