import Foundation
import UserNotifications

/// The daily reminder as the system shows it. The wording is a draft for the psychologist reviewer.
enum ReminderNotification {
    /// One identifier for every reminder, so scheduling again replaces it and tapping it can be recognized.
    static let identifier = "reminder.daily"

    static func request(at time: ReminderTime) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "reminder.title", defaultValue: "Caught a loop today?")
        content.body = String(
            localized: "reminder.body",
            defaultValue: "Take 20 seconds to log it, or try a quick tool if worry's around now.",
        )
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: time.hour, minute: time.minute),
            repeats: true,
        )
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
