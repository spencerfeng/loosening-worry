import FoundationModels
@testable import LooseningWorry
import Testing

/// The model answers in the options' own words, which read more naturally to it than ids; these map them back.
@MainActor
struct LoopReadingContentTests {
    private let options: [OptionKind: [OptionChoice]] = [
        .trigger: [OptionChoice(id: "custom.1", label: "Exams"), OptionChoice(.work, label: "Work")],
        .behavior: [OptionChoice(.keptChecking, label: "Kept checking")],
        .result: [OptionChoice(.moreWorry, label: "More worry"), OptionChoice(.notSure, label: "Not sure")],
    ]

    @Test
    func `each step's answer maps back to its option's id, and not said to no pick`() throws {
        let content = GeneratedContent(properties: [
            "trigger": "Exams", "behavior": "Kept checking", "result": LoopModelSchema.notSaid,
        ])

        let reading = try LoopModelSchema.reading(from: content, options: options)

        #expect(reading.picks == [.trigger: "custom.1", .behavior: "behavior.keptChecking"])
        #expect(reading.newOptions.isEmpty)
    }

    /// Kept even for a step that got a pick, so the eval can count a suggestion where an option already fit; the
    /// logger never offers those.
    @Test
    func `new options are kept trimmed, and blank ones dropped`() throws {
        let content = GeneratedContent(properties: [
            "trigger": LoopModelSchema.notSaid, "behavior": "Kept checking", "result": LoopModelSchema.notSaid,
            "newTrigger": " Landlord ", "newBehavior": "Phone", "newResult": "  ",
        ])

        let reading = try LoopModelSchema.reading(from: content, options: options)

        #expect(reading.newOptions == [.trigger: "Landlord", .behavior: "Phone"])
    }

    @Test
    func `a new option longer than three words is dropped`() throws {
        let content = GeneratedContent(properties: [
            "trigger": LoopModelSchema.notSaid, "behavior": LoopModelSchema.notSaid, "result": LoopModelSchema.notSaid,
            "newTrigger": "My landlord texted me again", "newBehavior": "Kept checking phone",
        ])

        let reading = try LoopModelSchema.reading(from: content, options: options)

        #expect(reading.newOptions == [.behavior: "Kept checking phone"])
    }

    /// Someone could call an option of their own "none"; the answer for "not said" must never be taken for it.
    @Test
    func `an option labeled none is an option like any other`() throws {
        let own: [OptionKind: [OptionChoice]] = [.trigger: [OptionChoice(id: "custom.none", label: "none")]]
        let content = GeneratedContent(properties: [
            "trigger": "none", "behavior": LoopModelSchema.notSaid, "result": LoopModelSchema.notSaid,
        ])

        let reading = try LoopModelSchema.reading(from: content, options: own)

        #expect(reading.picks == [.trigger: "custom.none"])
        #expect(LoopModelSchema.choices(for: .trigger, in: own) == ["none", LoopModelSchema.notSaid])
    }

    @Test
    func `the schema builds from the person's options`() throws {
        _ = try LoopModelSchema.schema(for: options)
    }

    @Test
    func `the schema offers each step's labels and not said`() {
        #expect(LoopModelSchema.choices(for: .trigger, in: options) == ["Exams", "Work", LoopModelSchema.notSaid])
    }
}
