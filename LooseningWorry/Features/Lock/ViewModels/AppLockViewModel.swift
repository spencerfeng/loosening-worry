import Foundation
import Observation
import SwiftUI

/// The app lock: whether the app is covered, and turning the lock on and off in Settings. It locks the app when it
/// opens, and when it comes back after more than `grace` away, and asks by itself each time.
@Observable @MainActor
final class AppLockViewModel {
    private(set) var isLocked: Bool
    /// What the person chose in Settings.
    private(set) var isOn: Bool
    /// How this device unlocks, which names the lock in Settings; `nil` when it has no passcode, so the lock is off
    /// and can't be turned on. Checked again each time the app comes back, as the person may have changed it.
    private(set) var method: LockMethod?
    /// How long the person can be away without being asked again.
    static let grace: TimeInterval = 60

    private let settings: LockSettings
    private let authenticator: any DeviceAuthenticator
    /// Whether the app is anywhere but in front: in the app switcher, under Control Center, or in the background.
    private var isAway = false
    private var leftAt: Date?
    /// Asking by itself happens on opening and on coming back from the background, never on returning from
    /// inactive: Face ID's own prompt makes the app inactive, so that would ask again straight after a cancel.
    private var asksOnReturn = true
    private var isAsking = false

    init(settings: LockSettings, authenticator: any DeviceAuthenticator) {
        self.settings = settings
        self.authenticator = authenticator
        isOn = settings.isOn
        isLocked = settings.isOn
        method = authenticator.availableMethod()
    }

    /// Covered while locked, and while the app is away with the lock on, so the app switcher shows nothing private.
    var isCovered: Bool {
        isLocked || (isOn && isAway)
    }

    /// Follows the app in and out of the foreground, locking it on return and asking for Face ID when it should.
    func sceneChanged(to phase: ScenePhase, at date: Date) async {
        switch phase {
        case .background:
            isAway = true
            leftAt = date
            asksOnReturn = true
        case .active:
            isAway = false
            cameBack(at: date)
            if asksOnReturn {
                asksOnReturn = false
                await unlock()
            }
        default:
            isAway = true
        }
    }

    /// Turning the lock on asks once, so it's only kept if Face ID, or the passcode, works here.
    func setLock(on: Bool) async {
        guard !isAsking else { return }
        if on {
            guard method != nil else { return }
            isAsking = true
            defer { isAsking = false }
            guard await authenticator.authenticate(for: .turnOn) else { return }
        }
        settings.isOn = on
        isOn = on
    }

    /// Asks for Face ID, or whatever the device uses; a failed or cancelled try leaves the app locked.
    /// A tap on Unlock while Face ID is already up is ignored.
    func unlock() async {
        guard isLocked, !isAsking else { return }
        isAsking = true
        defer { isAsking = false }
        if await authenticator.authenticate(for: .unlock) {
            isLocked = false
        }
    }

    private func cameBack(at date: Date) {
        defer { leftAt = nil }
        method = authenticator.availableMethod()
        // With the passcode gone nothing could unlock the app, so the lock gives way rather than shut the person out.
        if isOn, method == nil {
            settings.isOn = false
            isOn = false
            isLocked = false
        }
        guard isOn, let leftAt, date.timeIntervalSince(leftAt) > Self.grace else { return }
        isLocked = true
    }
}
