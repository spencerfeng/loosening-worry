import Evaluations
import Foundation
@testable import LooseningWorry
import Testing

/// Describe-a-loop against the ship bar in `Evals/loop-logging/README.md`. Run on an iPhone with Apple Intelligence.
///
/// The final set is kept back for an honest score: it runs only when `EVAL_FINAL` is set (pass
/// `TEST_RUNNER_EVAL_FINAL=1` to `xcodebuild`), so tuning never reads it by accident.
struct LoopLoggingEvals {
    static let practice = LoopLoggingEvaluation(split: .practice)
    static let final = LoopLoggingEvaluation(split: .final)

    @Test(.evaluates(practice, info: ["split": "practice"]))
    func `practice set`() {
        Self.expectShipBar(EvaluationContext.current.result)
    }

    @Test(
        .enabled(if: ProcessInfo.processInfo.environment["EVAL_FINAL"] == "1"),
        .evaluates(final, info: ["split": "final"]),
    )
    func `final set`() {
        Self.expectShipBar(EvaluationContext.current.result)
    }

    private static func expectShipBar(_ result: EvaluationResult) {
        for step in OptionKind.allCases {
            let right = result.aggregateValue(.mean(of: LoopMetrics.right(step)))
            let wrong = result.aggregateValue(.mean(of: LoopMetrics.wrong(step)))
            #expect(right >= 0.85, "\(step) right \(right.formatted(.percent))")
            #expect(wrong <= 0.05, "\(step) wrong \(wrong.formatted(.percent))")
        }
        #expect(result.aggregateValue(.mean(of: LoopMetrics.help)) == 1)
        let seconds = result.aggregateValue(.mean(of: LoopMetrics.seconds))
        #expect(seconds < 2, "\(seconds.formatted(.number.precision(.fractionLength(2)))) seconds per sentence")
        print(result.groupedSummary)
    }
}
