import os
import UserNotifications

/// Schedules the daily reminder with the system's notification center.
struct NotificationReminderScheduler: ReminderScheduler {
    /// The lesson the reminder names, looked up each time it's scheduled; `nil` once the course is done. It reads the
    /// app's main database context, so it runs on the main actor.
    let nextLesson: @MainActor () -> Lesson?

    private var center: UNUserNotificationCenter {
        .current()
    }

    func permissionStatus() async -> ReminderPermission {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notAsked
        case .denied: .denied
        // Provisional and ephemeral delivery still deliver the reminder.
        case .authorized, .provisional, .ephemeral: .allowed
        @unknown default: .denied
        }
    }

    /// A request that fails to reach the person counts as a refusal: the screen then says how to allow
    /// notifications in iOS Settings.
    func askPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            Self.logger.error("Couldn't ask for notification permission: \(error)")
            return false
        }
    }

    func scheduleDaily(at time: ReminderTime) async throws {
        let lesson = await nextLesson()
        try await center.add(ReminderNotification.request(at: time, next: lesson))
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [ReminderNotification.identifier])
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry",
        category: "Reminder",
    )
}
