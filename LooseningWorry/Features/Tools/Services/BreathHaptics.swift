import CoreHaptics
import os

/// Breathe's vibration: a soft continuous hum that swells over each in-breath and fades over the out-breath
/// (`BreathPattern.hapticCurve`), looping while the breathing runs, so someone can follow with their eyes closed.
/// Phones without Core Haptics get a tap at each turn instead, which `BreatheView` plays.
@MainActor
final class BreathHaptics {
    let isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    /// While the breathing runs, how far into the current breath it is, in seconds. Asked each time the vibration
    /// starts, including after the system stops or resets the engine, so it always lines up with the circle.
    private var offset: (() -> TimeInterval)?

    func start(offset: @escaping () -> TimeInterval) {
        self.offset = offset
        play()
    }

    func stop() {
        offset = nil
        if let player {
            do {
                try player.stop(atTime: CHHapticTimeImmediate)
            } catch {
                Self.logger.error("Couldn't stop the breathing haptics: \(error)")
            }
        }
        engine?.stop()
    }

    private func play() {
        guard isSupported, let offset else { return }
        do {
            let engine = try engine ?? makeEngine()
            self.engine = engine
            try engine.start()
            let player = try player ?? engine.makeAdvancedPlayer(with: Self.pattern())
            self.player = player
            player.loopEnabled = true
            player.loopEnd = BreathPattern.cycle / .seconds(1)
            // Where the breath is now that the engine is ready, set before playing so it starts in step.
            try player.seek(toOffset: offset())
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // The circle and words still guide; the next start builds everything afresh.
            Self.logger.error("Couldn't start the breathing haptics: \(error)")
            engine = nil
            player = nil
        }
    }

    /// The system can stop the engine (an interruption, such as a call) or reset it (the haptic server restarting);
    /// either way the player is gone, so the vibration starts again where the breath is, if it's still running.
    private func makeEngine() throws -> CHHapticEngine {
        let engine = try CHHapticEngine()
        engine.stoppedHandler = { [weak self] reason in
            Task { @MainActor in
                Self.logger.info("The breathing haptics stopped: \(reason.rawValue)")
                self?.restart()
            }
        }
        engine.resetHandler = { [weak self] in
            Task { @MainActor in
                self?.restart()
            }
        }
        return engine
    }

    private func restart() {
        player = nil
        play()
    }

    /// One breath: a continuous event as long as the breath, its strength following the curve.
    private static func pattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
            ],
            relativeTime: 0,
            duration: BreathPattern.cycle / .seconds(1),
        )
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: BreathPattern.hapticCurve.map {
                CHHapticParameterCurve.ControlPoint(relativeTime: $0.time, value: $0.intensity)
            },
            relativeTime: 0,
        )
        return try CHHapticPattern(events: [event], parameterCurves: [curve])
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Tools")
}
