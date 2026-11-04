import Foundation
@testable import LooseningWorry
import Testing

/// Checks the eval's own scoring and cases, without the model, so a wrong score is never blamed on it.
@MainActor
struct LoopCaseTests {
    @Test
    func `a step is right when its answer is one the case accepts, none included`() {
        #expect(LoopScore.step(answer: "trigger.work", expected: ["trigger.work", "trigger.deadline"]) == .right)
        #expect(LoopScore.step(answer: LoopScore.none, expected: ["trigger.news", LoopScore.none]) == .right)
    }

    @Test
    func `leaving a step empty that should be picked is not sure, not wrong`() {
        #expect(LoopScore.step(answer: LoopScore.none, expected: ["trigger.work"]) == .notSure)
    }

    @Test
    func `picking an option the case doesn't accept is wrong`() {
        #expect(LoopScore.step(answer: "trigger.news", expected: ["trigger.work"]) == .wrong)
        #expect(LoopScore.step(answer: "trigger.news", expected: [LoopScore.none]) == .wrong)
    }

    @Test
    func `a label is accepted when it contains an accepted word, ignoring case`() {
        let rule = NewOptionRule(accept: ["landlord"], required: true)

        #expect(rule.accepts("Landlord texts"))
        #expect(!rule.accepts("Rent"))
    }

    @Test
    func `every case decodes, and every expected id is one of its profile's options`() throws {
        let file = try CaseFile.bundled()
        #expect(file.cases.count == 82)

        for loopCase in file.cases {
            let options = try file.options(for: loopCase)
            for step in OptionKind.allCases {
                let ids = Set((options[step] ?? []).map(\.id) + [LoopScore.none])
                let unknown = loopCase.expect[step].filter { !ids.contains($0) }
                #expect(unknown.isEmpty, "\(loopCase.id) expects \(unknown) for \(step)")
            }
        }
    }

    @Test
    func `each profile adds its own options on top of the starters`() throws {
        let file = try CaseFile.bundled()
        let custom = try #require(file.cases.first { $0.profile == "custom" })

        let triggers = try file.options(for: custom)[.trigger] ?? []

        #expect(triggers.contains { $0.id == "custom.exams" && $0.label == "Exams" })
        #expect(triggers.contains { $0.id == "trigger.work" })
    }
}
