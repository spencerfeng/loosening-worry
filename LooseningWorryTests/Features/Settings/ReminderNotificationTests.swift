@testable import LooseningWorry
import Testing
import UserNotifications

struct ReminderNotificationTests {
    @Test
    func `the reminder invites a log, every day at the chosen time`() throws {
        let request = ReminderNotification.request(at: ReminderTime(hour: 7, minute: 30))

        #expect(request.content.title == "Caught a loop today?")
        #expect(request.content.body == "Take 20 seconds to log it, or try a quick tool if worry's around now.")
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.hour == 7)
        #expect(trigger.dateComponents.minute == 30)
        #expect(trigger.dateComponents.day == nil)
    }

    /// Scheduling again under the same identifier replaces the reminder, so there's only ever one.
    @Test
    func `every reminder shares one identifier`() {
        let morning = ReminderNotification.request(at: ReminderTime(hour: 7, minute: 0))
        let evening = ReminderNotification.request(at: .eightPM)

        #expect(morning.identifier == evening.identifier)
        #expect(morning.identifier == ReminderNotification.identifier)
    }
}
