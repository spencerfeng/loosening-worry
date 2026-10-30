import Foundation
@testable import LooseningWorry
import Testing

/// The reminder names the next lesson, so it's scheduled again whenever that changes.
@MainActor
final class CourseReminderTests {
    private let suiteName = "CourseReminderTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let scheduler = FakeReminderScheduler()

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private var settings: ReminderSettings {
        ReminderSettings(defaults: defaults)
    }

    @Test
    func `a reminder that's on is scheduled again at its time`() async {
        settings.isOn = true
        settings.time = ReminderTime(hour: 7, minute: 30)

        await CourseReminder(settings: settings, scheduler: scheduler).refresh()

        #expect(scheduler.scheduled == ReminderTime(hour: 7, minute: 30))
    }

    @Test
    func `a reminder that's off stays off`() async {
        await CourseReminder(settings: settings, scheduler: scheduler).refresh()

        #expect(scheduler.scheduled == nil)
    }
}
