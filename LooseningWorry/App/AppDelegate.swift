import UIKit
import UserNotifications

/// Receives taps on the daily reminder. It owns the root model, so a tap that launches the app still opens the
/// logger once the first screen appears.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let rootModel = RootViewModel()

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil,
    ) -> Bool {
        // Set before launch finishes, or a tap that launched the app is never delivered.
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
    ) async {
        let identifier = response.notification.request.identifier
        await MainActor.run { rootModel.openNotification(identifier: identifier) }
    }

    /// The reminder shows even while the app is open.
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
