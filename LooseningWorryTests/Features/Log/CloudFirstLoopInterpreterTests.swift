import Foundation
@testable import LooseningWorry
import Testing

private struct Offline: Error {}

/// Apple's Private Cloud Compute model reads better than the on-device one, so it reads when it can; the phone's own
/// model reads when it can't.
@MainActor
struct CloudFirstLoopInterpreterTests {
    private let cloud = FakeLoopInterpreter(reading: LoopReading(picks: [.trigger: "trigger.work"]))
    private let device = FakeLoopInterpreter(reading: LoopReading(picks: [.trigger: "trigger.health"]))

    private func read(_ interpreter: CloudFirstLoopInterpreter) async throws -> LoopReading {
        try await interpreter.read("Work again", options: [:])
    }

    @Test
    func `the cloud reads when it's available, and the phone isn't asked`() async throws {
        let reading = try await read(CloudFirstLoopInterpreter(cloud: cloud, device: device))

        #expect(reading.picks == [.trigger: "trigger.work"])
        #expect(device.asked.isEmpty)
    }

    @Test
    func `the phone reads when the cloud isn't available`() async throws {
        cloud.isAvailable = false

        let reading = try await read(CloudFirstLoopInterpreter(cloud: cloud, device: device))

        #expect(reading.picks == [.trigger: "trigger.health"])
        #expect(cloud.asked.isEmpty)
    }

    @Test(arguments: [(true, true), (true, false), (false, true), (false, false)])
    func `it can read when either can`(cloudAvailable: Bool, deviceAvailable: Bool) {
        cloud.isAvailable = cloudAvailable
        device.isAvailable = deviceAvailable

        let interpreter = CloudFirstLoopInterpreter(cloud: cloud, device: device)

        #expect(interpreter.isAvailable == (cloudAvailable || deviceAvailable))
    }

    /// Offline, rate limited or timed out: the person still gets a reading rather than "couldn't tell".
    @Test
    func `the phone reads when the cloud fails`() async throws {
        cloud.error = Offline()

        let reading = try await read(CloudFirstLoopInterpreter(cloud: cloud, device: device))

        #expect(cloud.asked.count == 1)
        #expect(reading.picks == [.trigger: "trigger.health"])
    }

    @Test
    func `the cloud's failure comes through when the phone can't read either`() async {
        cloud.error = Offline()
        device.isAvailable = false

        await #expect(throws: Offline.self) {
            try await read(CloudFirstLoopInterpreter(cloud: cloud, device: device))
        }
        #expect(device.asked.isEmpty)
    }

    /// The person left the logger; nobody is waiting for a reading.
    @Test
    func `a cancelled read isn't tried again on the phone`() async {
        cloud.error = CancellationError()

        await #expect(throws: CancellationError.self) {
            try await read(CloudFirstLoopInterpreter(cloud: cloud, device: device))
        }
        #expect(device.asked.isEmpty)
    }

    /// The network can report a cancelled request as its own error rather than as a cancellation.
    @Test
    func `a read cancelled while the cloud reads isn't tried again on the phone, whatever the cloud throws`() async {
        cloud.isHeld = true
        let interpreter = CloudFirstLoopInterpreter(cloud: cloud, device: device)
        let reading = Task { try await read(interpreter) }
        await cloud.untilHeld()

        reading.cancel()
        cloud.error = URLError(.cancelled)
        cloud.release()

        await #expect(throws: CancellationError.self) {
            try await reading.value
        }
        #expect(device.asked.isEmpty)
    }
}
