import Foundation
@testable import LooseningWorry
import Testing

@MainActor
struct LearnContentTests {
    private func done(_ days: [Int]) -> [LessonProgress] {
        days.map { day in
            let progress = LessonProgress(day: day)
            progress.completedAt = .now
            return progress
        }
    }

    @Test
    func `the course is split into three stages of ten days`() {
        let stages = LearnContent.stages(progress: [], catalog: .bundled)

        #expect(stages.map(\.number) == [1, 2, 3])
        #expect(stages.map { $0.rows.map(\.lesson.day) } == [Array(1 ... 10), Array(11 ... 20), Array(21 ... 30)])
    }

    /// Lessons can be read in any order, so the next one is the first not yet done.
    @Test
    func `each lesson is done, next or for later`() {
        let stages = LearnContent.stages(progress: done([1, 2, 4]), catalog: .bundled)

        let statuses = stages[0].rows.prefix(5).map(\.status)
        #expect(statuses == [.done, .done, .next, .done, .later])
    }

    /// A row Home saved for a revisit suggestion, with no date, isn't a finished lesson.
    @Test
    func `a lesson only counts as done once it has a date`() {
        let stages = LearnContent.stages(progress: [LessonProgress(day: 1)], catalog: .bundled)

        #expect(stages[0].rows[0].status == .next)
    }

    @Test
    func `once every lesson is done, none is next`() {
        let stages = LearnContent.stages(progress: done(Array(1 ... 30)), catalog: .bundled)

        #expect(stages.flatMap(\.rows).allSatisfy { $0.status == .done })
    }
}
