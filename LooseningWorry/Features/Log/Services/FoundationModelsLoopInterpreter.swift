import Foundation
import FoundationModels

/// Reads a described loop with Apple's on-device model. Nothing leaves the device.
@MainActor
struct FoundationModelsLoopInterpreter: LoopInterpreter {
    private let model = SystemLanguageModel.default

    /// Checked each time it's asked, so the field appears once the model is ready or Apple Intelligence is turned on.
    var isAvailable: Bool {
        model.availability == .available && model.supportsLocale()
    }

    func read(_ sentence: String, options: [OptionKind: [OptionChoice]]) async throws -> LoopReading {
        // A fresh session each time, so one loop's words never color the next.
        let session = LanguageModelSession(model: model, instructions: LoopModelSchema.instructions)
        let response = try await session.respond(
            to: sentence,
            schema: LoopModelSchema.schema(for: options),
            options: GenerationOptions(samplingMode: .greedy),
        )
        return try LoopModelSchema.reading(from: response.content, options: options)
    }
}

/// What the model is asked for: each step's answer chosen from the person's options in their own words, or `notSaid`,
/// and for a step none fits, a new option in the person's words.
enum LoopModelSchema {
    /// The answer for a step the words don't tell. Bracketed, so it can't be mistaken for an option someone named
    /// "none".
    static let notSaid = "(not said)"
    /// The longest new option offered, in words; the description asks for this, and longer ones are dropped.
    static let newOptionMaxWords = 3

    static let instructions = """
    A person describes a moment of worry in their own words. Fill in three steps from what they wrote:
    trigger, what set the worry off; behavior, what they did about it; result, how they felt afterward.
    For each step pick the closest option, or "(not said)" when their words don't say. Never guess a step they \
    didn't mention. Pick "Not sure" for the result only when they say they couldn't tell how they felt.
    When their words clearly tell a step but no option fits, answer "(not said)" and suggest a new option for it: \
    one to three words taken from what they wrote, capitalized like a title. Otherwise suggest nothing.
    """

    /// The answers the schema allows for `step`: its options' labels, then `notSaid`.
    static func choices(for step: OptionKind, in options: [OptionKind: [OptionChoice]]) -> [String] {
        (options[step] ?? []).map(\.label) + [notSaid]
    }

    static func schema(for options: [OptionKind: [OptionChoice]]) throws -> GenerationSchema {
        let properties = OptionKind.allCases.flatMap { step in
            [
                DynamicGenerationSchema.Property(
                    name: step.rawValue,
                    description: stepDescriptions[step],
                    schema: DynamicGenerationSchema(
                        name: step.rawValue + "Choice",
                        anyOf: choices(for: step, in: options),
                    ),
                ),
                DynamicGenerationSchema.Property(
                    name: newOptionProperty(for: step),
                    description: "Only when no option fits: a new one, 1–3 words from their text.",
                    schema: DynamicGenerationSchema(type: String.self),
                    isOptional: true,
                ),
            ]
        }
        return try GenerationSchema(
            root: DynamicGenerationSchema(name: "Loop", properties: properties),
            dependencies: [],
        )
    }

    /// Maps the model's answer back to ids. A label that isn't an option, or `notSaid`, picks nothing. New options are
    /// kept as the model gave them, trimmed, even for a step that got a pick, so the eval can count that mistake; the
    /// logger never offers those. One that's blank or longer than `newOptionMaxWords` is dropped.
    static func reading(from content: GeneratedContent, options: [OptionKind: [OptionChoice]]) throws -> LoopReading {
        var reading = LoopReading()
        for step in OptionKind.allCases {
            let label = try content.value(String.self, forProperty: step.rawValue)
            if let choice = options[step]?.first(where: { $0.label == label }) {
                reading.picks[step] = choice.id
            }
            let suggested = try content.value(String?.self, forProperty: newOptionProperty(for: step))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if
                let suggested,
                (1 ... newOptionMaxWords).contains(suggested.split(whereSeparator: \.isWhitespace).count)
            {
                reading.newOptions[step] = suggested
            }
        }
        return reading
    }

    private static func newOptionProperty(for step: OptionKind) -> String {
        "new" + step.rawValue.prefix(1).uppercased() + step.rawValue.dropFirst()
    }

    private static let stepDescriptions: [OptionKind: String] = [
        .trigger: "What set the worry off.",
        .behavior: "What they did about the worry.",
        .result: "How they felt afterward.",
    ]
}
