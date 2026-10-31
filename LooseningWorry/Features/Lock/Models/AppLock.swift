import Foundation

/// How this device proves it's the person: their face, finger or eyes, or only the passcode.
enum LockMethod {
    case faceID, touchID, opticID, passcode
}

/// Why the person is asked: the prompt says so, as turning the lock on isn't unlocking anything.
enum LockRequest {
    case unlock, turnOn
}

/// Asks the device to confirm it's the person. The real one is LocalAuthentication; tests use a fake.
@MainActor
protocol DeviceAuthenticator {
    /// `nil` when the device has no passcode, so nothing can lock the app.
    func availableMethod() -> LockMethod?
    /// Asks, falling back to the passcode; returns whether the person got through.
    func authenticate(for request: LockRequest) async -> Bool
}

/// Whether the app locks, kept on this device only: Face ID and the passcode belong to the device.
struct LockSettings {
    let defaults: UserDefaults

    var isOn: Bool {
        get { defaults.bool(forKey: Key.isOn) }
        nonmutating set { defaults.set(newValue, forKey: Key.isOn) }
    }

    private enum Key {
        static let isOn = "lock.isOn"
    }
}
