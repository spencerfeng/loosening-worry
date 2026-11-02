@testable import LooseningWorry

/// Stands in for Apple's models: reads every sentence as told, or fails.
@MainActor
final class FakeLoopInterpreter: LoopInterpreter {
    var isAvailable = true
    /// What every sentence reads as.
    var reading = LoopReading()
    /// Thrown instead of reading, when set.
    var error: Error?
    /// The sentences it was asked to read, and the options it was given for each.
    private(set) var asked: [(sentence: String, options: [OptionKind: [OptionChoice]])] = []

    init(reading: LoopReading = LoopReading()) {
        self.reading = reading
    }

    func read(_ sentence: String, options: [OptionKind: [OptionChoice]]) async throws -> LoopReading {
        asked.append((sentence, options))
        if isHeld {
            await withCheckedContinuation { held.append($0) }
        }
        if let error {
            throw error
        }
        return reading
    }

    /// While set, reading waits for `release()`, as the model takes a moment.
    var isHeld = false
    private var held: [CheckedContinuation<Void, Never>] = []

    /// Returns once a read is waiting on the hold.
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
