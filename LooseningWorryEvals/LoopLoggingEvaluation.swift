import Evaluations
import Foundation
import FoundationModels
@testable import LooseningWorry

/// Reads every case of one split with the real interpreter, and scores it as `Evals/loop-logging/README.md` says.
struct LoopLoggingEvaluation: Evaluation {
    let split: LoopCase.Split
    private let file: CaseFile

    struct ModelUnavailable: Error {}

    init(split: LoopCase.Split) {
        self.split = split
        do {
            file = try CaseFile.bundled()
        } catch {
            // Without the cases there's nothing to score; the scoring tests say why.
            fatalError("Couldn't read cases.json: \(error)")
        }
    }

    var dataset: some Loader<LoopCase> {
        ArrayLoader(samples: file.cases.filter { $0.split == split })
    }

    func subject(from sample: LoopCase) async throws -> ModelSubject<EvalReading> {
        let options = try file.options(for: sample)
        let clock = ContinuousClock()
        let start = clock.now
        let reading: LoopReading
        var failure: String?
        do {
            reading = try await Self.read(sample.text, options: options)
        } catch let error as LanguageModelError {
            // A refusal or a guardrail reads as nothing, as it does in the logger, which then says it couldn't tell;
            // leaving the case out would flatter the score. Anything else is the eval's own failure.
            switch error {
            case .refusal, .guardrailViolation:
                reading = LoopReading()
                failure = error.localizedDescription
            default:
                throw error
            }
        }
        let elapsed = start.duration(to: clock.now)
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        return ModelSubject(value: EvalReading(reading, seconds: seconds, failure: failure))
    }

    @MainActor
    private static func read(_ text: String, options: [OptionKind: [OptionChoice]]) async throws -> LoopReading {
        let interpreter = FoundationModelsLoopInterpreter()
        guard interpreter.isAvailable else { throw ModelUnavailable() }
        return try await interpreter.read(text, options: options)
    }

    var evaluators: Evaluators {
        MetricsEvaluator { sample, subject in
            // Crisis sentences are answered by the app's rules, not scored as the model's.
            guard sample.help != true else { return [] }
            return OptionKind.allCases.flatMap { step in
                let outcome = LoopScore.step(answer: subject.value.answer(for: step), expected: sample.expect[step])
                let why = "Read \(subject.value.answer(for: step)); accepts \(sample.expect[step])"
                return [
                    LoopMetrics.right(step).scoring(outcome == .right ? 1 : 0, rationale: why),
                    LoopMetrics.wrong(step).scoring(outcome == .wrong ? 1 : 0, rationale: why),
                ]
            }
        }
        MetricsEvaluator { sample, subject in
            guard sample.help != true else { return [] }
            return OptionKind.allCases.flatMap { step in
                Self.newOptionMetrics(for: step, sample: sample, reading: subject.value)
            }
        }
        Evaluator { (sample: LoopCase, _: ModelSubject<EvalReading>) in
            let spotted = CrisisWording.appears(in: sample.text)
            let wanted = sample.help == true
            return spotted == wanted
                ? LoopMetrics.help.passing()
                : LoopMetrics.help.failing(rationale: wanted ? "Help missing" : "Help shown for everyday words")
        }
        Evaluator { (_: LoopCase, subject: ModelSubject<EvalReading>) in
            subject.value.failure.map { LoopMetrics.answered.failing(rationale: $0) } ?? LoopMetrics.answered.passing()
        }
        Evaluator { (_: LoopCase, subject: ModelSubject<EvalReading>) in
            subject.value.seconds.map { LoopMetrics.seconds.scoring($0) } ?? LoopMetrics.seconds.ignore()
        }
    }

    /// A required suggestion should come with no pick for the step; a step the case doesn't list must get none; and a
    /// suggestion's label should hold an accepted word.
    private static func newOptionMetrics(for step: OptionKind, sample: LoopCase, reading: EvalReading) -> [Metric] {
        let suggested = reading.newOption(for: step)
        guard let rule = sample.newOptionRule(for: step) else {
            return [suggested == nil
                ? LoopMetrics.noUnwantedOption.scoring(1)
                : LoopMetrics.noUnwantedOption.scoring(0, rationale: "Suggested \(suggested ?? "") for \(step)")]
        }
        var metrics: [Metric] = []
        if rule.required {
            let shown = suggested != nil && reading.answer(for: step) == LoopScore.none
            metrics.append(LoopMetrics.requiredOption.scoring(
                shown ? 1 : 0,
                rationale: "Suggested \(suggested ?? "nothing")",
            ))
        }
        if let suggested {
            metrics.append(LoopMetrics.optionLabel.scoring(rule.accepts(suggested) ? 1 : 0, rationale: suggested))
        }
        return metrics
    }

    func aggregateMetrics(using aggregator: inout MetricsAggregator) {
        for step in OptionKind.allCases {
            aggregator.computeMean(of: LoopMetrics.right(step))
            aggregator.computeMean(of: LoopMetrics.wrong(step))
        }
        aggregator.computeMean(of: LoopMetrics.requiredOption)
        aggregator.computeMean(of: LoopMetrics.noUnwantedOption)
        aggregator.computeMean(of: LoopMetrics.optionLabel)
        aggregator.computeMean(of: LoopMetrics.help)
        aggregator.computeMean(of: LoopMetrics.answered)
        aggregator.computeMean(of: LoopMetrics.seconds)
        aggregator.computeMaximum(of: LoopMetrics.seconds)
    }
}

/// Scores a case on several metrics at once, such as one per step; `Evaluator` gives one.
struct MetricsEvaluator: EvaluatorProtocol {
    let score: @Sendable (LoopCase, ModelSubject<EvalReading>) -> [Metric]

    func metrics(subject: ModelSubject<EvalReading>, input: LoopCase) async throws -> [Metric] {
        score(input, subject)
    }
}

/// The scores the report shows. Rates are scored 1 or 0 per case, so their mean is the share of cases.
enum LoopMetrics {
    static func right(_ step: OptionKind) -> Metric {
        Metric("\(step.rawValue.capitalized) right")
    }

    static func wrong(_ step: OptionKind) -> Metric {
        Metric("\(step.rawValue.capitalized) wrong")
    }

    static let requiredOption = Metric("New option suggested when needed")
    static let noUnwantedOption = Metric("No new option where one fits")
    static let optionLabel = Metric("New option label accepted")
    static let help = Metric("Help matches crisis wording")
    static let answered = Metric("Answered without a refusal")
    static let seconds = Metric("Seconds per sentence")
}
