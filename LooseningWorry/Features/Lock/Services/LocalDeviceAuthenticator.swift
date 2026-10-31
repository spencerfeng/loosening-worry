import Foundation
import LocalAuthentication
import os

/// Face ID, Touch ID or Optic ID through LocalAuthentication, falling back to the device passcode.
struct LocalDeviceAuthenticator: DeviceAuthenticator {
    func availableMethod() -> LockMethod? {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No passcode is the expected reason; anything else is worth knowing about.
            if let error, error.code != LAError.passcodeNotSet.rawValue {
                Self.logger.error("Couldn't check how this device unlocks: \(error)")
            }
            return nil
        }
        // Biometrics count only once they're set up; until then the passcode is the way in.
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { return .passcode }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        case .none: return .passcode
        @unknown default: return .passcode
        }
    }

    func authenticate(for request: LockRequest) async -> Bool {
        let reason = switch request {
        case .unlock: String(localized: "lock.reason", defaultValue: "Unlock Loosening Worry")
        case .turnOn: String(localized: "lock.reason.turnOn", defaultValue: "Turn on the lock for Loosening Worry")
        }
        do {
            return try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch let error as LAError where [.userCancel, .appCancel, .systemCancel].contains(error.code) {
            return false
        } catch {
            Self.logger.error("Couldn't unlock: \(error)")
            return false
        }
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry",
        category: "Lock",
    )
}
