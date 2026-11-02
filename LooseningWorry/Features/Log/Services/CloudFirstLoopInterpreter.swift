import Foundation
import OSLog

/// Reads with Apple's Private Cloud Compute model, which reads loops far better than the on-device one, and with the
/// phone's own model when the cloud isn't available or its read fails.
@MainActor
struct CloudFirstLoopInterpreter: LoopInterpreter {
    let cloud: LoopInterpreter
    let device: LoopInterpreter

    var isAvailable: Bool {
        cloud.isAvailable || device.isAvailable
    }

    func read(_ sentence: String, options: [OptionKind: [OptionChoice]]) async throws -> LoopReading {
        guard cloud.isAvailable else { return try await device.read(sentence, options: options) }
        do {
            return try await cloud.read(sentence, options: options)
        } catch let error as CancellationError {
            throw error
        } catch {
            // Nobody is waiting for a reading, whatever error the cancelled request came back as.
            try Task.checkCancellation()
            // Offline, rate limited or timed out: the phone's model still gives the person a reading.
            guard device.isAvailable else { throw error }
            Self.logger.notice("The cloud couldn't read a described loop, so the phone will: \(error)")
            return try await device.read(sentence, options: options)
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Log")
}
