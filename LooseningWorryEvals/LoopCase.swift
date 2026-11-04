import Evaluations
import Foundation
@testable import LooseningWorry

/// `cases.json`: the hand-written sentences and what each should read as. See `Evals/loop-logging/README.md`.
struct CaseFile: Decodable {
    let version: Int
    let profiles: [String: Profile]
    let cases: [LoopCase]

    /// The options a person has: the starters, read from the app, and the ones they added.
    struct Profile: Decodable {
        let added: Steps<[AddedOption]>
    }

    struct AddedOption: Codable, Sendable {
        let id: String
        let label: String
    }

    struct MissingProfile: Error {
        let name: String
    }

    struct MissingFile: Error {}

    static func bundled() throws -> CaseFile {
        guard let url = Bundle(for: BundleToken.self).url(forResource: "cases", withExtension: "json") else {
            throw MissingFile()
        }
        return try JSONDecoder().decode(CaseFile.self, from: Data(contentsOf: url))
    }

    /// The choices the logger would show a person with the case's profile, in the same order: their own options
    /// before the starters, except results, where the starters lead.
    func options(for loopCase: LoopCase) throws -> [OptionKind: [OptionChoice]] {
        guard let profile = profiles[loopCase.profile] else { throw MissingProfile(name: loopCase.profile) }
        return Dictionary(uniqueKeysWithValues: OptionKind.allCases.map { step in
            let starters = OptionList.choices(for: step, saved: [])
            let added = profile.added[step].map { OptionChoice(id: $0.id, label: $0.label) }
            return (step, step == .result ? starters + added : added + starters)
        })
    }
}

private final class BundleToken {}

/// One value per step, as the cases write them: keyed `trigger`, `behavior` and `result`.
struct Steps<Value: Codable & Sendable>: Codable, Sendable {
    let trigger: Value
    let behavior: Value
    let result: Value

    subscript(step: OptionKind) -> Value {
        switch step {
        case .trigger: trigger
        case .behavior: behavior
        case .result: result
        }
    }
}

/// When a step should get a new option in the person's words.
struct NewOptionRule: Codable, Sendable {
    /// The label is right if it contains any one of these, ignoring case.
    let accept: [String]
    /// Whether leaving the suggestion out counts against the score.
    let required: Bool

    func accepts(_ label: String) -> Bool {
        accept.contains { label.localizedCaseInsensitiveContains($0) }
    }
}

/// One hand-written sentence and the answers counted as right.
struct LoopCase: SampleProtocol {
    enum Split: String, Codable, Sendable {
        case practice, final
    }

    let id: String
    let split: Split
    let kind: String
    let profile: String
    let text: String
    /// For each step, the option ids counted as right, or `LoopScore.none` when the step should be left empty.
    let expect: Steps<[String]>
    /// The steps that may get a new option; any other step must not.
    let newOptions: [String: NewOptionRule]?
    let note: String?

    var input: String {
        text
    }

    /// The first answer counted as right for each step, so the report can show it beside the model's.
    var expected: EvalReading? {
        EvalReading(
            trigger: expect.trigger.first ?? LoopScore.none,
            behavior: expect.behavior.first ?? LoopScore.none,
            result: expect.result.first ?? LoopScore.none,
            newOptions: [:],
            seconds: nil,
        )
    }

    func newOptionRule(for step: OptionKind) -> NewOptionRule? {
        newOptions?[step.rawValue]
    }
}

/// What the interpreter read from a case, as the report shows it: each step's option id or `LoopScore.none`, the new
/// options it suggested by step, how long it took, and why it gave no answer if it refused.
struct EvalReading: Codable, Sendable, Equatable {
    var trigger: String
    var behavior: String
    var result: String
    var newOptions: [String: String]
    var seconds: Double?
    /// Why the model gave no answer, when it refused or a guardrail stopped it.
    var failure: String?

    init(trigger: String, behavior: String, result: String, newOptions: [String: String], seconds: Double?) {
        self.trigger = trigger
        self.behavior = behavior
        self.result = result
        self.newOptions = newOptions
        self.seconds = seconds
    }

    init(_ reading: LoopReading, seconds: Double, failure: String?) {
        trigger = reading.picks[.trigger] ?? LoopScore.none
        behavior = reading.picks[.behavior] ?? LoopScore.none
        result = reading.picks[.result] ?? LoopScore.none
        newOptions = Dictionary(uniqueKeysWithValues: reading.newOptions.map { ($0.key.rawValue, $0.value) })
        self.seconds = seconds
        self.failure = failure
    }

    func answer(for step: OptionKind) -> String {
        switch step {
        case .trigger: trigger
        case .behavior: behavior
        case .result: result
        }
    }

    func newOption(for step: OptionKind) -> String? {
        newOptions[step.rawValue]
    }
}
