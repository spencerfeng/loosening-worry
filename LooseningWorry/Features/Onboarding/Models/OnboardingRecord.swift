import Foundation

/// Whether this device has been through onboarding. Kept on this device only, like the check-in: a new device asks
/// for its own notification permission and time, and waiting for synced data would leave first launch unsure.
struct OnboardingRecord {
    let defaults: UserDefaults

    /// The app's: kept in the standard defaults.
    static var standard: OnboardingRecord {
        OnboardingRecord(defaults: .standard)
    }

    var isFinished: Bool {
        get { defaults.bool(forKey: Key.isFinished) }
        nonmutating set { defaults.set(newValue, forKey: Key.isFinished) }
    }

    private enum Key {
        static let isFinished = "onboarding.isFinished"
    }
}

#if DEBUG
    extension OnboardingRecord {
        /// A device that has been through onboarding, for previews and tests: kept in its own defaults, never the
        /// app's.
        static var finished: OnboardingRecord {
            guard let defaults = UserDefaults(suiteName: "OnboardingRecord.finished") else {
                preconditionFailure("A named defaults suite always opens")
            }
            let record = OnboardingRecord(defaults: defaults)
            record.isFinished = true
            return record
        }
    }
#endif
