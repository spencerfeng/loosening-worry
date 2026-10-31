import Foundation
@testable import LooseningWorry
import SwiftUI
import Testing

@MainActor
final class AppLockViewModelTests {
    /// Each test gets its own defaults, so nothing leaks between tests or into the app.
    private let suiteName = "AppLockViewModelTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let authenticator = FakeAuthenticator()
    private let launch = Date(timeIntervalSince1970: 1_793_000_000)

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private var settings: LockSettings {
        LockSettings(defaults: defaults)
    }

    private func makeModel() -> AppLockViewModel {
        AppLockViewModel(settings: settings, authenticator: authenticator)
    }

    /// The app has opened and the person got through, with the lock on.
    private func makeOpenedModel() async -> AppLockViewModel {
        settings.isOn = true
        let model = makeModel()
        await model.sceneChanged(to: .active, at: launch)
        return model
    }

    // MARK: Opening

    @Test
    func `with the lock off, the app opens uncovered without asking`() async {
        let model = makeModel()

        await model.sceneChanged(to: .active, at: launch)

        #expect(model.isLocked == false)
        #expect(model.isCovered == false)
        #expect(authenticator.askCount == 0)
    }

    @Test
    func `with the lock on, the app opens covered`() {
        settings.isOn = true

        let model = makeModel()

        #expect(model.isLocked)
        #expect(model.isCovered)
    }

    @Test
    func `opening asks by itself, and getting through unlocks the app`() async {
        let model = await makeOpenedModel()

        #expect(authenticator.asked == [.unlock])
        #expect(model.isLocked == false)
        #expect(model.isCovered == false)
    }

    /// A failed or cancelled try leaves the cover up, with Unlock to try again.
    @Test
    func `a failed try keeps the app locked`() async {
        authenticator.succeeds = false

        let model = await makeOpenedModel()

        #expect(model.isLocked)
    }

    /// Face ID's own prompt makes the app briefly inactive, so asking on every return would ask again after a cancel.
    @Test
    func `after a cancel, the prompt going away doesn't ask again`() async {
        authenticator.succeeds = false
        let model = await makeOpenedModel()

        await model.sceneChanged(to: .inactive, at: launch)
        await model.sceneChanged(to: .active, at: launch)

        #expect(authenticator.askCount == 1)
        #expect(model.isLocked)
    }

    // MARK: Coming back

    /// A quick trip to another app, to copy something or answer a message, doesn't ask again.
    @Test(arguments: [(30.0, false), (60, false), (61, true), (3600, true)])
    func `coming back locks the app only after more than a minute away`(seconds: Double, locks: Bool) async {
        let model = await makeOpenedModel()
        authenticator.succeeds = false

        await model.sceneChanged(to: .background, at: launch)
        await model.sceneChanged(to: .active, at: launch.addingTimeInterval(seconds))

        #expect(model.isLocked == locks)
        #expect(authenticator.askCount == (locks ? 2 : 1))
    }

    @Test
    func `with the lock off, coming back never locks`() async {
        let model = makeModel()
        await model.sceneChanged(to: .active, at: launch)

        await model.sceneChanged(to: .background, at: launch)
        await model.sceneChanged(to: .active, at: launch.addingTimeInterval(3600))

        #expect(model.isLocked == false)
    }

    /// The app switcher's picture is taken while the app is away, so it shows the cover, not a loop.
    @Test
    func `with the lock on, the app is covered while it's away, without locking`() async {
        let model = await makeOpenedModel()

        await model.sceneChanged(to: .inactive, at: launch)

        #expect(model.isCovered)
        #expect(model.isLocked == false)

        await model.sceneChanged(to: .active, at: launch)

        #expect(model.isCovered == false)
    }

    @Test
    func `with the lock off, the app isn't covered while it's away`() async {
        let model = makeModel()

        await model.sceneChanged(to: .background, at: launch)

        #expect(model.isCovered == false)
    }

    // MARK: Turning it on and off

    /// Asking once proves Face ID works here, so no one locks themselves out by accident.
    @Test
    func `turning the lock on asks once, then keeps it on without locking straight away`() async {
        let model = makeModel()

        await model.setLock(on: true)

        #expect(authenticator.asked == [.turnOn])
        #expect(model.isOn)
        #expect(settings.isOn)
        #expect(model.isLocked == false)
    }

    @Test
    func `if that first try fails, the lock stays off`() async {
        authenticator.succeeds = false
        let model = makeModel()

        await model.setLock(on: true)

        #expect(model.isOn == false)
        #expect(settings.isOn == false)
    }

    @Test
    func `turning the lock off doesn't ask`() async {
        let model = await makeOpenedModel()

        await model.setLock(on: false)

        #expect(authenticator.askCount == 1)
        #expect(settings.isOn == false)
    }

    @Test
    func `a second tap while Face ID is up doesn't ask again`() async {
        authenticator.isHeld = true
        let model = makeModel()
        let first = Task { await model.setLock(on: true) }
        await authenticator.untilHeld()

        let second = Task { await model.setLock(on: true) }
        await Task.yield()
        authenticator.release()
        await first.value
        await second.value

        #expect(authenticator.askCount == 1)
        #expect(model.isOn)
    }

    // MARK: The device's way in

    @Test
    func `the lock is named after the device's way of unlocking`() {
        authenticator.method = .touchID

        #expect(makeModel().method == .touchID)
    }

    /// The person may set up Face ID in iOS Settings and come back with Settings still open.
    @Test
    func `coming back picks up a new way of unlocking`() async {
        authenticator.method = .passcode
        let model = makeModel()

        authenticator.method = .faceID
        await model.sceneChanged(to: .active, at: launch)

        #expect(model.method == .faceID)
    }

    @Test
    func `without a passcode on the device, the lock can't be turned on`() async {
        authenticator.method = nil
        let model = makeModel()

        await model.setLock(on: true)

        #expect(model.method == nil)
        #expect(authenticator.askCount == 0)
        #expect(settings.isOn == false)
    }

    /// Nothing could unlock it, so the app would stay covered for good.
    @Test
    func `if the passcode was removed while the lock was on, the app opens and the lock turns off`() async {
        settings.isOn = true
        authenticator.method = nil
        let model = makeModel()

        await model.sceneChanged(to: .active, at: launch)

        #expect(model.isLocked == false)
        #expect(model.isOn == false)
        #expect(settings.isOn == false)
        #expect(authenticator.askCount == 0)
    }

    @Test
    func `if the passcode is removed while the app is away, coming back opens it and turns the lock off`() async {
        let model = await makeOpenedModel()
        await model.sceneChanged(to: .background, at: launch)

        authenticator.method = nil
        await model.sceneChanged(to: .active, at: launch.addingTimeInterval(3600))

        #expect(model.isLocked == false)
        #expect(model.isOn == false)
        #expect(authenticator.askCount == 1)
    }

    /// Opening asks by itself; tapping Unlock while Face ID is up mustn't ask again.
    @Test
    func `a second unlock while Face ID is up doesn't ask again`() async {
        settings.isOn = true
        authenticator.isHeld = true
        let model = makeModel()
        let first = Task { await model.unlock() }
        await authenticator.untilHeld()

        let second = Task { await model.unlock() }
        await Task.yield()
        authenticator.release()
        await first.value
        await second.value

        #expect(authenticator.askCount == 1)
        #expect(model.isLocked == false)
    }
}
