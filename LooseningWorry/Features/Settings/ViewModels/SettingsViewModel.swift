import Foundation
import Observation

/// Settings: the daily reminder (the check-in, to the person), and links to the person's options and to Help.
@Observable @MainActor
final class SettingsViewModel {
    /// What the person chose. The switch and time show it straight away, while the change is still being applied.
    private(set) var isReminderOn: Bool
    private(set) var reminderTime: ReminderTime
    /// Notifications are off for the app, so the reminder can't be on; the screen says how to turn them on.
    private(set) var notificationsOff = false
    /// The system couldn't schedule the reminder; the switch and time show what's actually scheduled.
    private(set) var reminderFailed = false

    private let settings: ReminderSettings
    private let scheduler: any ReminderScheduler
    private var isApplying = false

    init(settings: ReminderSettings, scheduler: any ReminderScheduler) {
        self.settings = settings
        self.scheduler = scheduler
        isReminderOn = settings.isOn
        reminderTime = settings.time
    }

    /// Turning the reminder on asks for notification permission the first time.
    func setReminder(on: Bool) async {
        isReminderOn = on
        await apply()
    }

    func setTime(_ time: ReminderTime) async {
        reminderTime = time
        await apply()
    }

    /// Re-reads the permission each time Settings opens, since the person can change it in iOS Settings meanwhile.
    func refresh() async {
        let denied = await scheduler.permissionStatus() == .denied
        if denied, isReminderOn {
            await setReminder(on: false)
            notificationsOff = true
        } else if !denied {
            notificationsOff = false
        }
    }

    /// Brings the scheduled reminder in line with what the person chose, one change at a time: a change made while
    /// another is still being applied (during iOS's prompt, or while scrolling the time) is applied after it, so the
    /// last choice is the one that's kept.
    private func apply() async {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }
        while isReminderOn != settings.isOn || reminderTime != settings.time {
            let (on, time) = (isReminderOn, reminderTime)
            if on, !settings.isOn || time != settings.time {
                guard await scheduler.isAllowed() else {
                    notificationsOff = true
                    isReminderOn = false
                    settings.time = time
                    continue
                }
                guard await schedule(at: time) else {
                    // What's on screen goes back to what's actually scheduled.
                    isReminderOn = settings.isOn
                    reminderTime = settings.time
                    return
                }
            } else if !on {
                scheduler.cancel()
                reminderFailed = false
            }
            settings.isOn = on
            settings.time = time
        }
    }

    private func schedule(at time: ReminderTime) async -> Bool {
        do {
            try await scheduler.scheduleDaily(at: time)
            reminderFailed = false
            return true
        } catch {
            reminderFailed = true
            return false
        }
    }
}
