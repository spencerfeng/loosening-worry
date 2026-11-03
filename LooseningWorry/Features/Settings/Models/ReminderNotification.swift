import Foundation
import UserNotifications

/// The daily reminder as the system shows it: the next lesson during the course, an invitation to check in after it.
enum ReminderNotification {
    /// One identifier for every reminder, so scheduling again replaces it and tapping it can be recognized.
    static let identifier = "reminder.daily"
    /// The day of the lesson a reminder names, so tapping it opens that lesson.
    static let lessonDayKey = "lessonDay"

    /// `next` is the lesson to name, or `nil` once the course is done. The text is fixed when it's scheduled, so
    /// `CourseReminder` schedules it again whenever the next lesson changes.
    static func request(at time: ReminderTime, next: Lesson?) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        if let next {
            content.title = String(localized: "reminder.lesson.title", defaultValue: "Day \(next.day) is ready")
            content.body = String(
                localized: "reminder.lesson.body",
                defaultValue: "\(next.title) · \(next.minutes) min",
            )
            content.userInfo = [lessonDayKey: next.day]
        } else {
            content.title = String(localized: "reminder.checkIn.title", defaultValue: "How are you right now?")
            content.body = String(localized: "reminder.checkIn.body", defaultValue: "Take a few seconds to check in.")
        }
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: time.hour, minute: time.minute),
            repeats: true,
        )
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
