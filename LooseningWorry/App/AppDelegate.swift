import UIKit
import UserNotifications

/// Receives taps on the daily reminder. It owns the root model, so a tap that launches the app still opens the
/// lesson or the logger once the first screen appears.
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
        let request = response.notification.request
        let identifier = request.identifier
        let lessonDay = request.content.userInfo[ReminderNotification.lessonDayKey] as? Int
        await MainActor.run { rootModel.openNotification(identifier: identifier, lessonDay: lessonDay) }
    }

    /// The reminder shows even while the app is open.
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
