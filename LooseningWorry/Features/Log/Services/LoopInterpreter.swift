/// Reads a sentence describing a loop into the person's options. The real ones are Apple's models; tests use a fake.
@MainActor
protocol LoopInterpreter {
    /// Whether it can read at all on this device now.
    var isAvailable: Bool { get }
    /// Reads `sentence`, picking for each step from `options` only.
    func read(_ sentence: String, options: [OptionKind: [OptionChoice]]) async throws -> LoopReading
}
