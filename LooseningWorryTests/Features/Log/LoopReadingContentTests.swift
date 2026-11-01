import FoundationModels
@testable import LooseningWorry
import Testing

/// The model answers in the options' own words, which read more naturally to it than ids; these map them back. It
/// quotes the words that tell each step first, and a pick counts only when the quote is really in the sentence.
@MainActor
struct LoopReadingContentTests {
    private let options: [OptionKind: [OptionChoice]] = [
        .trigger: [OptionChoice(id: "custom.1", label: "Exams"), OptionChoice(.work, label: "Work")],
        .behavior: [OptionChoice(.keptChecking, label: "Kept checking")],
        .result: [OptionChoice(.moreWorry, label: "More worry"), OptionChoice(.notSure, label: "Not sure")],
    ]

    private let sentence = "Exams on Friday, I kept checking the timetable."

    /// Content as the model gives it: each step's quote and answer, then any new options.
    private func content(
        _ steps: [OptionKind: (quote: String, answer: String)],
        newOptions: [String: String] = [:],
    ) -> GeneratedContent {
        var properties: [(String, any ConvertibleToGeneratedContent)] = []
        for step in OptionKind.allCases {
            let (quote, answer) = steps[step] ?? ("", LoopModelSchema.somethingElse)
            properties += [(step.rawValue + "Quote", quote), (step.rawValue, answer)]
        }
        properties += newOptions.map { ($0.key, $0.value) }
        return GeneratedContent(properties: properties) { first, _ in first }
    }

    @Test
    func `each quoted step's answer maps back to its option's id, and an empty quote to no pick`() throws {
        let content = content([
            .trigger: ("Exams on Friday", "Exams"),
            .behavior: ("kept checking the timetable", "Kept checking"),
            .result: ("", LoopModelSchema.somethingElse),
        ])

        let reading = try LoopModelSchema.reading(from: content, options: options, sentence: sentence)

        #expect(reading.picks == [.trigger: "custom.1", .behavior: "behavior.keptChecking"])
        #expect(reading.newOptions.isEmpty)
    }

    /// Words that tell a step no option fits leave it for the person to pick.
    @Test
    func `a quoted step answered something else gets no pick`() throws {
        let content = content([.trigger: ("Exams on Friday", LoopModelSchema.somethingElse)])

        let reading = try LoopModelSchema.reading(from: content, options: options, sentence: sentence)

        #expect(reading.picks.isEmpty)
    }

    /// The model guesses a step from what usually happens; with nothing to quote, the guess is dropped.
    @Test
    func `a step with nothing quoted gets no pick, whatever option came with it`() throws {
        let content = content([.trigger: ("Exams on Friday", "Exams"), .result: ("", "More worry")])

        let reading = try LoopModelSchema.reading(from: content, options: options, sentence: sentence)

        #expect(reading.picks == [.trigger: "custom.1"])
    }

    @Test
    func `a quote that isn't in the sentence gets no pick`() throws {
        let content = content([.result: ("felt much worse", "More worry")])

        let reading = try LoopModelSchema.reading(from: content, options: options, sentence: sentence)

        #expect(reading.picks.isEmpty)
    }

    @Test(arguments: ["exams ON friday", "\u{201C}Exams on Friday,\u{201D}", "  kept   checking  "])
    func `a quote matches regardless of case, spacing and the punctuation around it`(quote: String) throws {
        let content = content([.trigger: (quote, "Exams")])

        let reading = try LoopModelSchema.reading(from: content, options: options, sentence: sentence)

        #expect(reading.picks == [.trigger: "custom.1"])
    }

    @Test
    func `a quote matches across straight and curly apostrophes`() throws {
        let content = content([.result: ("can't tell", "Not sure")])

        let reading = try LoopModelSchema.reading(
            from: content,
            options: options,
            sentence: "Asked again, honestly can\u{2019}t tell if it helped.",
        )

        #expect(reading.picks == [.result: "result.notSure"])
    }

    /// Kept even for a step that got a pick, so the eval can count a suggestion where an option already fit; the
    /// logger never offers those.
    @Test
    func `new options are kept trimmed, and blank ones dropped`() throws {
        let content = content(
            [.behavior: ("kept checking", "Kept checking")],
            newOptions: ["newTrigger": " Landlord ", "newBehavior": "Phone", "newResult": "  "],
        )

        let reading = try LoopModelSchema.reading(from: content, options: options, sentence: sentence)

        #expect(reading.newOptions == [.trigger: "Landlord", .behavior: "Phone"])
    }

    @Test
    func `a new option longer than three words is dropped`() throws {
        let content = content(
            [:],
            newOptions: ["newTrigger": "My landlord texted me again", "newBehavior": "Kept checking phone"],
        )

        let reading = try LoopModelSchema.reading(from: content, options: options, sentence: sentence)

        #expect(reading.newOptions == [.behavior: "Kept checking phone"])
    }

    /// Someone could call an option of their own "none"; it's picked like any other.
    @Test
    func `an option labeled none is an option like any other`() throws {
        let own: [OptionKind: [OptionChoice]] = [.trigger: [OptionChoice(id: "custom.none", label: "none")]]
        let content = content([.trigger: ("Exams", "none")])

        let reading = try LoopModelSchema.reading(from: content, options: own, sentence: sentence)

        #expect(reading.picks == [.trigger: "custom.none"])
        #expect(LoopModelSchema.choices(for: .trigger, in: own) == ["none", LoopModelSchema.somethingElse])
    }

    @Test
    func `the schema builds from the person's options`() throws {
        _ = try LoopModelSchema.schema(for: options)
    }

    @Test
    func `the schema offers each step's labels and something else`() {
        #expect(LoopModelSchema.choices(for: .trigger, in: options) == ["Exams", "Work", LoopModelSchema.somethingElse])
    }
}
