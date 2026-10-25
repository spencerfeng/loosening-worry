import Foundation
import os

/// The behaviors a new user most likely logs after each starter trigger, from `starter-pairs.json`, most likely
/// first. Until a trigger has enough loops of the person's own, step 2 offers these first.
///
/// The map is a draft for the psychologist reviewer.
struct StarterPairs: Sendable {
    private let behaviorsByTrigger: [StarterID: [StarterID]]

    /// Reads the map from JSON keyed by starter id, so a reviewer can edit it without touching code.
    /// - Throws: If the JSON is malformed, or an id names no starter.
    init(json: Data) throws {
        let raw = try JSONDecoder().decode([String: [String]].self, from: json)
        var behaviorsByTrigger: [StarterID: [StarterID]] = [:]
        for (trigger, behaviors) in raw {
            try behaviorsByTrigger[Self.starter(trigger)] = try behaviors.map(Self.starter)
        }
        self.behaviorsByTrigger = behaviorsByTrigger
    }

    /// The behaviors to offer first after `trigger`, or none if the map has no entry for it.
    func behaviors(after trigger: StarterID) -> [StarterID] {
        behaviorsByTrigger[trigger] ?? []
    }

    /// The map shipped with the app. Tests check it loads and covers every starter trigger.
    static let bundled = loaded(
        from: Bundle.main.url(forResource: "starter-pairs", withExtension: "json").flatMap { try? Data(contentsOf: $0) }
    )

    /// The map in `data`, or an empty one if it can't be read: step 2 then falls back to overall use, which still
    /// works. The tests catch a broken file before it ships.
    static func loaded(from data: Data?) -> StarterPairs {
        do {
            guard let data else { throw UnknownStarter(id: "starter-pairs.json") }
            return try StarterPairs(json: data)
        } catch {
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Log")
                .error("Couldn't read the starter pairs: \(error)")
            return StarterPairs(behaviorsByTrigger: [:])
        }
    }

    private init(behaviorsByTrigger: [StarterID: [StarterID]]) {
        self.behaviorsByTrigger = behaviorsByTrigger
    }

    private struct UnknownStarter: Error {
        let id: String
    }

    private static func starter(_ id: String) throws -> StarterID {
        guard let starter = StarterID(rawValue: id) else { throw UnknownStarter(id: id) }
        return starter
    }
}
