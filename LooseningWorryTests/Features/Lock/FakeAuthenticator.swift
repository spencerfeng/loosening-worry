@testable import LooseningWorry

/// Stands in for Face ID: says which way the device unlocks, and answers as told.
@MainActor
final class FakeAuthenticator: DeviceAuthenticator {
    var method: LockMethod? = .faceID
    /// What the person does when asked.
    var succeeds = true
    /// Why it was asked, each time.
    private(set) var asked: [LockRequest] = []

    var askCount: Int {
        asked.count
    }

    func availableMethod() -> LockMethod? {
        method
    }

    func authenticate(for request: LockRequest) async -> Bool {
        asked.append(request)
        if isHeld {
            await withCheckedContinuation { held.append($0) }
        }
        return succeeds
    }

    /// While set, asking waits for `release()`, as it does while Face ID is on screen.
    var isHeld = false
    private var held: [CheckedContinuation<Void, Never>] = []

    /// Returns once a request is waiting on the hold.
    func untilHeld() async {
        while held.isEmpty {
            await Task.yield()
        }
    }

    func release() {
        isHeld = false
        held.forEach { $0.resume() }
        held = []
    }
}
