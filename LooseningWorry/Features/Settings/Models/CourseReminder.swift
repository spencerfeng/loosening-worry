import Foundation
import os

/// Keeps the daily reminder naming the next lesson: schedules it again, at the person's time, when a lesson is
/// finished here or progress syncs from another device. A reminder that's off stays off.
@MainActor
struct CourseReminder {
    let settings: ReminderSettings
    let scheduler: any ReminderScheduler

    func refresh() async {
        guard settings.isOn else { return }
        do {
            try await scheduler.scheduleDaily(at: settings.time)
        } catch {
            // The reminder already scheduled stays, naming an earlier lesson; the next refresh tries again.
            Self.logger.error("Couldn't schedule the reminder again: \(error)")
        }
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry",
        category: "Reminder",
    )
}
