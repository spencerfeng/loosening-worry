import Foundation
@testable import LooseningWorry
import Testing

struct LessonCatalogTests {
    @Test
    func `the course has thirty lessons, one a day, in order`() {
        let lessons = LessonCatalog.bundled.lessons

        #expect(lessons.map(\.day) == Array(1 ... 30))
        #expect(lessons.allSatisfy { !$0.title.isEmpty && $0.minutes > 0 })
    }

    @Test(arguments: [(1, "Welcome"), (12, "Worry is a habit, not a fact"), (30, "Keep going")])
    func `each day has its title`(day: Int, title: String) {
        #expect(LessonCatalog.bundled.lesson(day: day)?.title == title)
    }

    /// A broken file must not stop Home; the tests above catch it before it ships.
    @Test
    func `a file that can't be read gives no lessons`() {
        #expect(LessonCatalog.loaded(from: Data("not json".utf8)).lessons.isEmpty)
        #expect(LessonCatalog.loaded(from: nil).lessons.isEmpty)
    }
}
