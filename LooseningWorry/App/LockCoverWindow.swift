import os
import SwiftUI
import UIKit

/// Shows the lock's cover in its own window above the app's, so it sits over any sheet or full-screen screen too,
/// and whatever was open underneath, a half-logged loop or a lesson, is still there after unlocking.
@MainActor
final class LockCoverWindow {
    private var window: UIWindow?
    /// The app's own window, handed the keyboard and VoiceOver back once the cover goes.
    private weak var appWindow: UIWindow?

    func show(_ isCovered: Bool, lock: AppLockViewModel) {
        guard isCovered else {
            window?.isHidden = true
            window = nil
            appWindow?.makeKey()
            return
        }
        guard window == nil else { return }
        // The app has one scene: iPhone only, no multiple windows.
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            Self.logger.error("No window scene to put the lock's cover in")
            return
        }
        appWindow = scene.keyWindow
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        let host = UIHostingController(rootView: LockView(lock: lock))
        host.view.backgroundColor = .clear
        // Nothing underneath can be reached while it's covered: not the keyboard of an open note, not VoiceOver.
        host.view.accessibilityViewIsModal = true
        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry",
        category: "Lock",
    )
}
