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
        return try LoopModelSchema.reading(from: response.content, options: options, sentence: sentence)
    }
}

/// What the model is asked for: for each step, the words that tell it quoted from the sentence, then its answer chosen
/// from the person's options in their own words, or `somethingElse`; and for a step none fits, a new option in their
/// words.
///
/// Left to judge whether the words tell a step, the model guesses from what usually happens: "couldn't stop googling
/// my symptoms" ends in More worry. Quoting is a task it does better, and a quote can be checked: a step counts only
/// when its quote is really in the sentence.
enum LoopModelSchema {
    /// The answer when the quote is empty or no option means the same as it. Worded like an option: the model
    /// shunned an answer that wasn't, such as "(not said)", and squeezed the words into a starter instead.
    static let somethingElse = "Something else"
    /// The longest new option offered, in words; the description asks for this, and longer ones are dropped.
    static let newOptionMaxWords = 3

    static let instructions = """
    A person describes a moment of worry in their own words. Fill in three steps from what they wrote:
    trigger, what set the worry off; behavior, what they did about it; result, how they felt afterward.
    For each step, first copy the exact words from their text that tell it, or leave the quote empty when no words \
    do. Never guess a step they didn't write about. Then pick the option that means the same as the quote, or \
    "Something else" when the quote is empty or none does. Pick "Not sure" for the result only when they say they \
    couldn't tell how they felt.
    When their words clearly tell a step but no option fits, answer "Something else" and suggest a new option for it: \
    one to three words taken from what they wrote, capitalized like a title. Otherwise suggest nothing.
    """

    /// The answers the schema allows for `step`: its options' labels, then `somethingElse`.
    static func choices(for step: OptionKind, in options: [OptionKind: [OptionChoice]]) -> [String] {
        (options[step] ?? []).map(\.label) + [somethingElse]
    }

    static func schema(for options: [OptionKind: [OptionChoice]]) throws -> GenerationSchema {
        let properties = OptionKind.allCases.flatMap { step in
            [
                // Asked before the answer, so the model looks for the words before a likely option can tempt it.
                DynamicGenerationSchema.Property(
                    name: quoteProperty(for: step),
                    description: quoteDescriptions[step],
                    schema: DynamicGenerationSchema(type: String.self),
                ),
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

    /// Maps the model's answer back to ids. A step picks nothing unless its quote is in `sentence`, whatever option
    /// came
    /// with it; nor does a label that isn't an option, or `somethingElse`. New options are kept as the model gave them,
    /// trimmed, even for a step that got a pick, so the eval can count that mistake; the logger never offers those. One
    /// that's blank or longer than `newOptionMaxWords` is dropped.
    static func reading(
        from content: GeneratedContent,
        options: [OptionKind: [OptionChoice]],
        sentence: String,
    ) throws -> LoopReading {
        var reading = LoopReading()
        let words = comparable(sentence)
        for step in OptionKind.allCases {
            let quote = try comparable(content.value(String.self, forProperty: quoteProperty(for: step)))
            let label = try content.value(String.self, forProperty: step.rawValue)
            if
                !quote.isEmpty, words.contains(quote),
                let choice = options[step]?.first(where: { $0.label == label })
            {
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

    /// Text as a quote is compared: lowercase, with curly apostrophes straightened, runs of spaces made one, and no
    /// punctuation or spaces at either end. The model often trims or tidies what it copies.
    private static func comparable(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespaces).union(.symbols))
    }

    private static func quoteProperty(for step: OptionKind) -> String {
        step.rawValue + "Quote"
    }

    private static func newOptionProperty(for step: OptionKind) -> String {
        "new" + step.rawValue.prefix(1).uppercased() + step.rawValue.dropFirst()
    }

    private static let quoteDescriptions: [OptionKind: String] = [
        .trigger: "The exact words from their text that say what set the worry off, or empty.",
        .behavior: "The exact words from their text that say what they did about the worry, or empty.",
        .result: "The exact words from their text that say how they felt afterward, or empty.",
    ]

    private static let stepDescriptions: [OptionKind: String] = [
        .trigger: "What set the worry off.",
        .behavior: "What they did about the worry.",
        .result: "How they felt afterward.",
    ]
}
