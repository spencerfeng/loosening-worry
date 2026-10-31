import Foundation
@testable import LooseningWorry
import Testing
import UIKit

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

    @Test
    func `a lesson is a run of cards, from the hook to today's task`() throws {
        let lesson = try #require(LessonCatalog.bundled.lesson(day: 2))

        #expect(lesson.cards.map(\.kind) == [.hook, .idea, .idea, .idea, .example, .tryIt, .task])
        #expect(lesson.cards[1].title == "Three parts, every time")
        #expect(lesson.cards[1].body.hasPrefix("Habits run as small loops with three parts. A **trigger** sets it off"))
        #expect(lesson.cards[4].title == "\"Got a minute?\"")
        #expect(lesson.cards[5].seconds == 45)
        #expect(lesson.cards[6].title == "Log your first loop")
        #expect(lesson.cards[6].action == .logLoop)
    }

    @Test(arguments: LessonCatalog.bundled.lessons)
    func `every lesson follows the card template`(lesson: Lesson) {
        let kinds = lesson.cards.map(\.kind)
        let ideas = kinds.count { $0 == .idea }

        #expect(kinds.first == .hook && kinds.last == .task, "Day \(lesson.day)")
        #expect((2 ... 3).contains(ideas), "Day \(lesson.day)")
        #expect(kinds.count { $0 == .example } == 1 && kinds.count { $0 == .tryIt } == 1, "Day \(lesson.day)")
        #expect(lesson.cards.allSatisfy { !$0.body.isEmpty }, "Day \(lesson.day)")
        #expect(
            lesson.cards.filter { [.idea, .example].contains($0.kind) }.allSatisfy { $0.title != nil },
            "Day \(lesson.day)",
        )
        #expect(lesson.cards.first { $0.kind == .tryIt }?.seconds != nil, "Day \(lesson.day)")
        #expect(lesson.cards.last?.title != nil, "Day \(lesson.day)")
    }

    /// Onboarding sets the daily check-in, so Day 1's task is one to do away from the app: there's nothing to open.
    @Test
    func `the first day's task is to notice worry switching on`() throws {
        let task = try #require(LessonCatalog.bundled.lesson(day: 1)?.cards.last)

        #expect(task.title == "Catch worry switching on")
        #expect(task.body.contains("There it is."))
        #expect(task.action == nil)
        #expect(task.footer != nil)
    }

    /// Every task after Day 1 takes the person somewhere in the app.
    @Test(arguments: LessonCatalog.bundled.lessons.dropFirst())
    func `later tasks open something`(lesson: Lesson) {
        #expect(lesson.cards.last?.action != nil, "Day \(lesson.day)")
    }

    @Test
    func `illustrations are named by day and card`() throws {
        let lesson = try #require(LessonCatalog.bundled.lesson(day: 2))

        #expect(lesson.cards.indices.map { lesson.illustration(at: $0) } == [
            "lesson2.hook", "lesson2.idea1", "lesson2.idea2", "lesson2.idea3", "lesson2.example", "lesson2.try",
            "lesson2.task",
        ])
    }

    /// A card names a tint only once its illustration is in the app.
    @Test(arguments: LessonCatalog.bundled.lessons)
    func `every card with a tint has its illustration`(lesson: Lesson) {
        for index in lesson.cards.indices {
            guard let name = lesson.illustration(at: index) else { continue }
            #expect(UIImage(named: name) != nil, "\(name) is missing from the asset catalog")
        }
    }

    /// Tools are named as they are everywhere else; any other word is a mistake in the file.
    @Test(arguments: [
        ("logLoop", LessonAction.logLoop),
        ("openInsights", .openInsights),
        ("openSettings", .openSettings),
        ("curious", .tool(.curious)),
        ("breathe", .tool(.breathe)),
        ("noteIt", .tool(.noteIt)),
        ("beKind", .tool(.beKind)),
    ])
    func `today's task is read from its word`(word: String, action: LessonAction) throws {
        #expect(try JSONDecoder().decode(LessonAction.self, from: Data("\"\(word)\"".utf8)) == action)
    }

    @Test
    func `a task with an unknown word doesn't load`() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(LessonAction.self, from: Data("\"dance\"".utf8))
        }
    }

    /// A broken file must not stop Home; the tests above catch it before it ships.
    @Test
    func `a file that can't be read gives no lessons`() {
        #expect(LessonCatalog.loaded(from: Data("not json".utf8)).lessons.isEmpty)
        #expect(LessonCatalog.loaded(from: nil).lessons.isEmpty)
    }
}

extension Lesson: CustomTestStringConvertible {
    public var testDescription: String {
        "Day \(day)"
    }
}
