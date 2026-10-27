import Foundation
@testable import LooseningWorry
import Testing

@MainActor
final class SettingsViewModelTests {
    /// Each test gets its own defaults, so nothing leaks between tests or into the app.
    private let suiteName = "SettingsViewModelTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let scheduler = FakeReminderScheduler()

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeModel() -> SettingsViewModel {
        SettingsViewModel(settings: ReminderSettings(defaults: defaults), scheduler: scheduler)
    }

    @Test
    func `the daily reminder starts off, set for 8 pm`() {
        let model = makeModel()

        #expect(model.isReminderOn == false)
        #expect(model.reminderTime == ReminderTime(hour: 20, minute: 0))
        #expect(model.notificationsOff == false)
    }

    @Test
    func `turning the reminder on asks for permission, then schedules it daily and remembers it`() async {
        let model = makeModel()

        await model.setReminder(on: true)

        #expect(scheduler.askCount == 1)
        #expect(scheduler.scheduled == .eightPM)
        #expect(model.isReminderOn)
        #expect(makeModel().isReminderOn)
    }

    @Test
    func `if the person refuses notifications, the reminder stays off and the screen says so`() async {
        scheduler.allowsWhenAsked = false
        let model = makeModel()

        await model.setReminder(on: true)

        #expect(model.isReminderOn == false)
        #expect(model.notificationsOff)
        #expect(scheduler.scheduled == nil)
        #expect(makeModel().isReminderOn == false)
    }

    /// iOS asks only once; after that, only iOS Settings can turn notifications back on.
    @Test
    func `when notifications are already off, turning the reminder on doesn't ask again`() async {
        scheduler.permission = .denied
        let model = makeModel()

        await model.setReminder(on: true)

        #expect(scheduler.askCount == 0)
        #expect(model.isReminderOn == false)
        #expect(model.notificationsOff)
    }

    /// Once allowed, the reminder can be turned on without asking again.
    @Test
    func `when notifications are already allowed, the reminder turns on without asking`() async {
        scheduler.permission = .allowed
        let model = makeModel()

        await model.setReminder(on: true)

        #expect(scheduler.askCount == 0)
        #expect(model.isReminderOn)
    }

    @Test
    func `turning the reminder off cancels it and remembers that`() async {
        let model = makeModel()
        await model.setReminder(on: true)

        await model.setReminder(on: false)

        #expect(scheduler.scheduled == nil)
        #expect(model.isReminderOn == false)
        #expect(makeModel().isReminderOn == false)
        #expect(scheduler.askCount == 1)
    }

    @Test
    func `changing the time while the reminder is on moves it to the new time`() async {
        let model = makeModel()
        await model.setReminder(on: true)

        await model.setTime(ReminderTime(hour: 7, minute: 30))

        #expect(model.reminderTime == ReminderTime(hour: 7, minute: 30))
        #expect(scheduler.scheduled == ReminderTime(hour: 7, minute: 30))
        #expect(makeModel().reminderTime == ReminderTime(hour: 7, minute: 30))
    }

    @Test
    func `changing the time while the reminder is off only remembers it`() async {
        let model = makeModel()

        await model.setTime(ReminderTime(hour: 21, minute: 15))

        #expect(scheduler.scheduled == nil)
        #expect(scheduler.askCount == 0)
        #expect(makeModel().reminderTime == ReminderTime(hour: 21, minute: 15))
    }

    /// The switch never claims a reminder that won't arrive.
    @Test
    func `if notifications were turned off in iOS Settings, the reminder shows as off when Settings opens`() async {
        await makeModel().setReminder(on: true)
        scheduler.permission = .denied
        let model = makeModel()

        await model.refresh()

        #expect(model.isReminderOn == false)
        #expect(model.notificationsOff)
        #expect(scheduler.scheduled == nil)
        #expect(makeModel().isReminderOn == false)
    }

    @Test
    func `once notifications are allowed again, the note goes`() async {
        scheduler.permission = .denied
        let model = makeModel()
        await model.setReminder(on: true)
        scheduler.permission = .allowed

        await model.refresh()

        #expect(model.notificationsOff == false)
        #expect(model.isReminderOn == false)
    }

    @Test
    func `if the reminder can't be scheduled, it stays off and the screen says so`() async {
        scheduler.schedulingFails = true
        let model = makeModel()

        await model.setReminder(on: true)

        #expect(model.isReminderOn == false)
        #expect(model.reminderFailed)
        #expect(makeModel().isReminderOn == false)
    }

    /// The reminder already scheduled is still the one that will arrive.
    @Test
    func `if the new time can't be scheduled, the old time stays`() async {
        let model = makeModel()
        await model.setReminder(on: true)
        scheduler.schedulingFails = true

        await model.setTime(ReminderTime(hour: 7, minute: 0))

        #expect(model.reminderTime == .eightPM)
        #expect(model.reminderFailed)
        #expect(makeModel().reminderTime == .eightPM)
    }

    @Test
    func `the next change that works clears the message`() async {
        scheduler.schedulingFails = true
        let model = makeModel()
        await model.setReminder(on: true)
        scheduler.schedulingFails = false

        await model.setReminder(on: true)

        #expect(model.reminderFailed == false)
        #expect(model.isReminderOn)
    }

    /// The switch moves as soon as it's tapped, rather than snapping back while iOS shows its prompt.
    @Test
    func `while iOS is asking for permission, the switch already shows on`() async {
        scheduler.isHeld = true
        let model = makeModel()

        let turningOn = Task { await model.setReminder(on: true) }
        await scheduler.untilHeld()

        #expect(model.isReminderOn)
        scheduler.release()
        await turningOn.value
        #expect(model.isReminderOn)
        #expect(scheduler.scheduled == .eightPM)
    }

    @Test
    func `turning the reminder off while iOS is still asking leaves it off`() async {
        scheduler.isHeld = true
        let model = makeModel()

        let turningOn = Task { await model.setReminder(on: true) }
        await scheduler.untilHeld()
        await model.setReminder(on: false)
        scheduler.release()
        await turningOn.value

        #expect(model.isReminderOn == false)
        #expect(scheduler.scheduled == nil)
        #expect(makeModel().isReminderOn == false)
    }

    /// Scrolling the time picker sets several times in a row; the last one picked is the one that arrives.
    @Test
    func `a time picked while the last one is still being set is the one kept`() async {
        scheduler.permission = .allowed
        let model = makeModel()
        await model.setReminder(on: true)
        scheduler.isHeld = true

        let first = Task { await model.setTime(ReminderTime(hour: 7, minute: 0)) }
        await scheduler.untilHeld()
        let second = Task { await model.setTime(ReminderTime(hour: 7, minute: 30)) }
        await Task.yield()
        scheduler.release()
        await first.value
        await second.value

        #expect(model.reminderTime == ReminderTime(hour: 7, minute: 30))
        #expect(scheduler.scheduled == ReminderTime(hour: 7, minute: 30))
        #expect(makeModel().reminderTime == ReminderTime(hour: 7, minute: 30))
    }

    @Test
    func `turning the reminder off clears the message`() async {
        let model = makeModel()
        await model.setReminder(on: true)
        scheduler.schedulingFails = true
        await model.setTime(ReminderTime(hour: 7, minute: 0))

        await model.setReminder(on: false)

        #expect(model.reminderFailed == false)
    }
}

/// Stands in for the notification center: records what was scheduled, and answers permission as told.
@MainActor
final class FakeReminderScheduler: ReminderScheduler {
    var permission = ReminderPermission.notAsked
    /// What the person answers when asked.
    var allowsWhenAsked = true
    private(set) var askCount = 0
    private(set) var scheduled: ReminderTime?
    var schedulingFails = false
    /// While set, asking and scheduling wait for `release()`, as they do while iOS shows its prompt.
    var isHeld = false
    private var held: [CheckedContinuation<Void, Never>] = []

    /// Returns once a call is waiting on the hold.
    func untilHeld() async {
        while held.isEmpty {
            await Task.yield()
        }
    }

    /// Lets the waiting calls go, newest first: the system can finish requests in any order.
    func release() {
        isHeld = false
        held.reversed().forEach { $0.resume() }
        held = []
    }

    func permissionStatus() async -> ReminderPermission {
        permission
    }

    func askPermission() async -> Bool {
        await waitIfHeld()
        askCount += 1
        permission = allowsWhenAsked ? .allowed : .denied
        return allowsWhenAsked
    }

    func scheduleDaily(at time: ReminderTime) async throws {
        await waitIfHeld()
        if schedulingFails {
            throw SchedulingFailed()
        }
        scheduled = time
    }

    func cancel() {
        scheduled = nil
    }

    private func waitIfHeld() async {
        guard isHeld else { return }
        await withCheckedContinuation { held.append($0) }
    }
}

private struct SchedulingFailed: Error {}
