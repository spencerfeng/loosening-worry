import FoundationModels

/// Reads a described loop with Apple's on-device model. Nothing leaves the phone.
@MainActor
struct OnDeviceLoopInterpreter: LoopInterpreter {
    private let model = SystemLanguageModel.default

    /// Checked each time it's asked, so the field appears once the model is ready or Apple Intelligence is turned on.
    var isAvailable: Bool {
        model.availability == .available && model.supportsLocale()
    }

    func read(_ sentence: String, options: [OptionKind: [OptionChoice]]) async throws -> LoopReading {
        try await LoopModelSchema.read(sentence, options: options, with: model)
    }
}

/// Reads a described loop with Apple's Private Cloud Compute model. The words go to Apple's servers, which keep
/// nothing and which Apple itself can't read.
@MainActor
struct PrivateCloudLoopInterpreter: LoopInterpreter {
    private let model = PrivateCloudComputeLanguageModel()

    var isAvailable: Bool {
        model.isAvailable
    }

    func read(_ sentence: String, options: [OptionKind: [OptionChoice]]) async throws -> LoopReading {
        try await LoopModelSchema.read(sentence, options: options, with: model)
    }
}
