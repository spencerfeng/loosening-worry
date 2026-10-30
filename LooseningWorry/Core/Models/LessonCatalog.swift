import Foundation
import os

/// One day of the 30-day course: a run of cards, from the hook to today's task.
struct Lesson: Decodable, Equatable, Sendable {
    let day: Int
    let title: String
    /// How long it takes to read.
    let minutes: Int
    let cards: [LessonCard]

    /// The asset name of a card's illustration, such as "lesson2.idea1"; `nil` while the card has none.
    func illustration(at index: Int) -> String? {
        guard cards.indices.contains(index), cards[index].tint != nil else { return nil }
        let slot = switch cards[index].kind {
        case .hook: "hook"
        case .idea: "idea\(cards[...index].count { $0.kind == .idea })"
        case .example: "example"
        case .tryIt: "try"
        case .task: "task"
        }
        return "lesson\(day).\(slot)"
    }
}

/// One screen of a lesson. The words come straight from `lessons.json`, with `**bold**` and `*italic*` marked inline; a
/// translation is a copy of the whole file.
struct LessonCard: Decodable, Equatable, Sendable {
    enum Kind: String, Decodable, Sendable {
        case hook, idea, example, tryIt, task
    }

    /// The panel behind a card's illustration, one of the tool hues.
    enum Tint: String, Decodable, Sendable {
        case violet, blue, amber, green
    }

    let kind: Kind
    /// An idea's or example's heading, or today's task in a few words; the hook and the exercise have none.
    let title: String?
    let body: String
    /// How long "Try it now" takes.
    let seconds: Int?
    /// What today's task button opens.
    let action: LessonAction?
    /// A line under today's task; only day 1 has one.
    let footer: String?
    /// Set once the card has an illustration; a card without one shows its words alone.
    let tint: Tint?
}

extension Lesson: Identifiable {
    var id: Int {
        day
    }
}

/// Where today's task button goes once the lesson is done. In `lessons.json` it's a word: a tool's own name, such as
/// "breathe", or one of the other places.
enum LessonAction: Equatable, Sendable {
    case logLoop, openInsights, openSettings, setReminder
    case tool(QuickTool)
}

extension LessonAction: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        if let tool = QuickTool(rawValue: name) {
            self = .tool(tool)
            return
        }
        switch name {
        case "logLoop": self = .logLoop
        case "openInsights": self = .openInsights
        case "openSettings": self = .openSettings
        case "setReminder": self = .setReminder
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown task \(name)")
        }
    }
}

/// The course's lessons, from `lessons.json`.
struct LessonCatalog: Sendable {
    /// In day order.
    let lessons: [Lesson]

    init(json: Data) throws {
        lessons = try JSONDecoder().decode([Lesson].self, from: json).sorted { $0.day < $1.day }
    }

    func lesson(day: Int) -> Lesson? {
        lessons.first { $0.day == day }
    }

    /// The lessons shipped with the app. Tests check there are thirty, one a day.
    static let bundled: LessonCatalog = {
        guard let url = Bundle.main.url(forResource: "lessons", withExtension: "json") else {
            return loaded(from: nil)
        }
        do {
            return try loaded(from: Data(contentsOf: url))
        } catch {
            logger.error("Couldn't read lessons.json: \(error)")
            return LessonCatalog(lessons: [])
        }
    }()

    /// The lessons in `data`, or none if there's no file or it can't be read: Home then leaves the lesson card out.
    static func loaded(from data: Data?) -> LessonCatalog {
        guard let data else {
            logger.error("lessons.json is missing from the app")
            return LessonCatalog(lessons: [])
        }
        do {
            return try LessonCatalog(json: data)
        } catch {
            logger.error("Couldn't decode lessons.json: \(error)")
            return LessonCatalog(lessons: [])
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Lessons")

    private init(lessons: [Lesson]) {
        self.lessons = lessons
    }
}
