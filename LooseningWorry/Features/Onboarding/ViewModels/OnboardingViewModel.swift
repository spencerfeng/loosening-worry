import Foundation
import Observation
import os

/// The five screens a new device opens on, in order.
enum OnboardingStep: CaseIterable {
    case welcome, loop, uses, goodToKnow, checkIn
}

/// Onboarding: what the app is for, how a loop works and how to use the app, then a daily check-in time.
@Observable @MainActor
final class OnboardingViewModel {
    /// Set by Continue, or by swiping between screens.
    var step = OnboardingStep.welcome
    /// Set by a suggestion, or by the time picker.
    var checkInTime: ReminderTime
    /// Set while iOS asks about notifications and the check-in is scheduled; the buttons wait meanwhile.
    private(set) var isTurningOn = false

    private let settings: ReminderSettings
    private let scheduler: any ReminderScheduler
    private let finish: () -> Void

    init(settings: ReminderSettings, scheduler: any ReminderScheduler, finish: @escaping () -> Void) {
        self.settings = settings
        self.scheduler = scheduler
        self.finish = finish
        checkInTime = settings.time
    }

    /// The suggestion the check-in time matches, if any.
    var preset: CheckInPreset? {
        CheckInPreset.allCases.first { $0.time == checkInTime }
    }

    func pick(_ preset: CheckInPreset) {
        checkInTime = preset.time
    }

    /// Keeps the chosen time and schedules the check-in if the person allows notifications. Onboarding finishes
    /// either way: a refusal or a failure leaves the check-in off, for Settings to turn on later.
    func turnOnCheckIn() async {
        guard !isTurningOn else { return }
        isTurningOn = true
        settings.time = checkInTime
        if await scheduler.isAllowed() {
            do {
                try await scheduler.scheduleDaily(at: checkInTime)
                settings.isOn = true
            } catch {
                Self.logger.error("Couldn't schedule the check-in: \(error)")
            }
        }
        finish()
    }

    /// Not now: nothing is asked or kept; the check-in can be set in Settings any time.
    func skipCheckIn() {
        guard !isTurningOn else { return }
        finish()
    }

    func next() {
        let steps = OnboardingStep.allCases
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else { return }
        step = steps[index + 1]
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry",
        category: "Onboarding",
    )
}
