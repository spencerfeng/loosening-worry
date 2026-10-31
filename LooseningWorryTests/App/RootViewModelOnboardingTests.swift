import Foundation
@testable import LooseningWorry
import Testing

@MainActor
final class RootViewModelOnboardingTests {
    /// Each test gets its own defaults, so nothing leaks between tests or into the app.
    private let suiteName = "RootViewModelOnboardingTests.\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeModel() -> RootViewModel {
        RootViewModel(onboarding: OnboardingRecord(defaults: defaults))
    }

    @Test
    func `a device that hasn't been through onboarding opens on it`() {
        #expect(makeModel().isOnboarding)
    }

    @Test
    func `finishing onboarding lands on Home, and the device doesn't show it again`() {
        let model = makeModel()
        model.select(.insights)

        model.finishOnboarding()

        #expect(model.isOnboarding == false)
        #expect(model.selectedTab == .home)
        #expect(makeModel().isOnboarding == false)
    }

    /// The tabs aren't there yet, so a lesson or the logger would wait behind onboarding and pop up as it finishes.
    @Test(arguments: [1, nil])
    func `a notification tapped during onboarding opens nothing, then or after`(lessonDay: Int?) {
        let model = makeModel()

        model.openNotification(identifier: ReminderNotification.identifier, lessonDay: lessonDay)
        model.finishOnboarding()
        model.screenClosed()

        #expect(model.readingLesson == nil)
        #expect(model.isLogSheetPresented == false)
    }
}
