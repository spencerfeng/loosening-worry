import Foundation

/// The time of day the daily reminder arrives, in the person's own clock.
struct ReminderTime: Equatable {
    let hour: Int
    let minute: Int

    static let eightPM = ReminderTime(hour: 20, minute: 0)
}

/// The time picker works in dates; only the hour and minute matter.
extension ReminderTime {
    init(date: Date, calendar: Calendar = .current) {
        // Asked for, so always present.
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    /// This time on `day`, for the picker to show.
    func date(on day: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
}

/// Whether this device lets the app send notifications.
enum ReminderPermission {
    /// The person hasn't been asked yet.
    case notAsked
    case allowed
    /// Refused when asked, or turned off later in iOS Settings.
    case denied
}

/// Schedules the daily reminder with the system. The real one is the notification center; tests use a fake.
@MainActor
protocol ReminderScheduler {
    func permissionStatus() async -> ReminderPermission
    /// Asks the person, and returns whether they allowed notifications.
    func askPermission() async -> Bool
    /// Replaces any reminder already scheduled.
    func scheduleDaily(at time: ReminderTime) async throws
    func cancel()
}

/// The reminder switch and time, kept on this device only: each device asks for its own notification permission,
/// so a synced setting could say "on" where nothing will arrive.
struct ReminderSettings {
    let defaults: UserDefaults

    var isOn: Bool {
        get { defaults.bool(forKey: Key.isOn) }
        nonmutating set { defaults.set(newValue, forKey: Key.isOn) }
    }

    /// 8 pm until the person picks a time.
    var time: ReminderTime {
        get {
            guard
                let hour = defaults.object(forKey: Key.hour) as? Int,
                let minute = defaults.object(forKey: Key.minute) as? Int
            else { return .eightPM }
            return ReminderTime(hour: hour, minute: minute)
        }
        nonmutating set {
            defaults.set(newValue.hour, forKey: Key.hour)
            defaults.set(newValue.minute, forKey: Key.minute)
        }
    }

    private enum Key {
        static let isOn = "reminder.isOn"
        static let hour = "reminder.hour"
        static let minute = "reminder.minute"
    }
}
