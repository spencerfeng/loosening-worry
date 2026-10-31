import Foundation
@testable import LooseningWorry
import Testing

@MainActor
final class OnboardingViewModelTests {
    /// Each test gets its own defaults, so nothing leaks between tests or into the app.
    private let suiteName = "OnboardingViewModelTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let scheduler = FakeReminderScheduler()
    private var finishCount = 0

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private var settings: ReminderSettings {
        ReminderSettings(defaults: defaults)
    }

    private func makeModel() -> OnboardingViewModel {
        OnboardingViewModel(settings: settings, scheduler: scheduler) { [unowned self] in
            finishCount += 1
        }
    }

    @Test
    func `starts on Welcome, and Continue moves through each screen to the check-in`() {
        let model = makeModel()
        var seen = [model.step]

        for _ in 1 ..< OnboardingStep.allCases.count {
            model.next()
            seen.append(model.step)
        }

        #expect(seen == [.welcome, .loop, .uses, .goodToKnow, .checkIn])
    }

    @Test
    func `the check-in starts at 8 pm, which is Evening`() {
        let model = makeModel()

        #expect(model.checkInTime == .eightPM)
        #expect(model.preset == .evening)
    }

    @Test(arguments: [
        (CheckInPreset.morning, ReminderTime(hour: 8, minute: 0)),
        (.midday, ReminderTime(hour: 12, minute: 30)),
        (.evening, ReminderTime(hour: 20, minute: 0)),
    ])
    func `picking a suggested time sets the check-in to it`(preset: CheckInPreset, time: ReminderTime) {
        let model = makeModel()

        model.pick(preset)

        #expect(model.checkInTime == time)
        #expect(model.preset == preset)
    }

    @Test
    func `a time of the person's own matches no suggestion`() {
        let model = makeModel()

        model.checkInTime = ReminderTime(hour: 7, minute: 15)

        #expect(model.preset == nil)
    }

    @Test
    func `turning on the check-in asks for permission, schedules it at the chosen time and finishes`() async {
        let model = makeModel()
        model.pick(.morning)

        await model.turnOnCheckIn()

        #expect(scheduler.askCount == 1)
        #expect(scheduler.scheduled == CheckInPreset.morning.time)
        #expect(settings.isOn)
        #expect(settings.time == CheckInPreset.morning.time)
        #expect(finishCount == 1)
    }

    @Test
    func `if the person refuses notifications, the check-in stays off with their time kept, and onboarding finishes`(
    ) async {
        scheduler.allowsWhenAsked = false
        let model = makeModel()
        model.pick(.midday)

        await model.turnOnCheckIn()

        #expect(scheduler.scheduled == nil)
        #expect(settings.isOn == false)
        #expect(settings.time == CheckInPreset.midday.time)
        #expect(finishCount == 1)
    }

    /// iOS asks only once; after that, only iOS Settings can turn notifications back on.
    @Test
    func `when notifications are already off, turning on the check-in doesn't ask again`() async {
        scheduler.permission = .denied
        let model = makeModel()

        await model.turnOnCheckIn()

        #expect(scheduler.askCount == 0)
        #expect(settings.isOn == false)
        #expect(finishCount == 1)
    }

    @Test
    func `if the check-in can't be scheduled, it stays off and onboarding still finishes`() async {
        scheduler.schedulingFails = true
        let model = makeModel()

        await model.turnOnCheckIn()

        #expect(settings.isOn == false)
        #expect(finishCount == 1)
    }

    @Test
    func `choosing Not now finishes without asking for permission or setting a check-in`() {
        let model = makeModel()
        model.pick(.morning)

        model.skipCheckIn()

        #expect(scheduler.askCount == 0)
        #expect(scheduler.scheduled == nil)
        #expect(settings.isOn == false)
        #expect(settings.time == .eightPM)
        #expect(finishCount == 1)
    }

    /// iOS's prompt can take a while; tapping again, or Not now, meanwhile changes nothing.
    @Test
    func `while iOS asks about notifications, the buttons wait and onboarding finishes once`() async {
        scheduler.isHeld = true
        let model = makeModel()
        let turningOn = Task { await model.turnOnCheckIn() }
        await scheduler.untilHeld()

        #expect(model.isTurningOn)
        await model.turnOnCheckIn()
        model.skipCheckIn()
        scheduler.release()
        await turningOn.value

        #expect(scheduler.askCount == 1)
        #expect(settings.isOn)
        #expect(finishCount == 1)
    }
}
