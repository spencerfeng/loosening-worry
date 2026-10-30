@testable import LooseningWorry
import Testing
import UserNotifications

struct ReminderNotificationTests {
    /// During the course the reminder is for the next lesson, which leads on to its task.
    @Test
    func `during the course the reminder names the next lesson`() throws {
        let lesson = try #require(LessonCatalog.bundled.lesson(day: 3))

        let request = ReminderNotification.request(at: .eightPM, next: lesson)

        #expect(request.content.title == "Day 3 is ready")
        #expect(request.content.body == "Worry as a behavior · 5 min")
        #expect(request.content.userInfo[ReminderNotification.lessonDayKey] as? Int == 3)
    }

    @Test
    func `after the course the reminder invites a log, every day at the chosen time`() throws {
        let request = ReminderNotification.request(at: ReminderTime(hour: 7, minute: 30), next: nil)

        #expect(request.content.title == "Caught a loop today?")
        #expect(request.content.body == "Take 20 seconds to log it, or try a quick tool if worry's around now.")
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.hour == 7)
        #expect(trigger.dateComponents.minute == 30)
        #expect(trigger.dateComponents.day == nil)
        #expect(request.content.userInfo[ReminderNotification.lessonDayKey] == nil)
    }

    /// Scheduling again under the same identifier replaces the reminder, so there's only ever one.
    @Test
    func `every reminder shares one identifier`() {
        let morning = ReminderNotification.request(at: ReminderTime(hour: 7, minute: 0), next: nil)
        let evening = ReminderNotification.request(at: .eightPM, next: nil)

        #expect(morning.identifier == evening.identifier)
        #expect(morning.identifier == ReminderNotification.identifier)
    }
}
