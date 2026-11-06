import Foundation
import SwiftData

/// Saves the loops a person logs.
@MainActor
struct LoopStore {
    let context: ModelContext

    /// Adds `loop` and saves it now, so it's stored by the time the logger closes. If saving fails the loop is taken
    /// out again, so trying once more doesn't add a second copy.
    func add(_ loop: Loop) throws {
        context.insert(loop)
        do {
            try context.save()
        } catch {
            context.delete(loop)
            throw error
        }
    }

    /// The loops with `loop`'s trigger and habit, oldest first, `loop` included once stored. A tool's id is never a
    /// habit's, so loops met with a tool never match.
    func loops(like loop: Loop) throws -> [Loop] {
        let (triggerID, behaviorID) = (loop.triggerID, loop.behaviorID)
        return try context.fetch(FetchDescriptor<Loop>(
            predicate: #Predicate { $0.triggerID == triggerID && $0.behaviorID == behaviorID },
            sortBy: [SortDescriptor(\.createdAt)],
        ))
    }

    /// The latest loop set off by the trigger with id `triggerID` that has a note, so its words can be shown again;
    /// `nil` if none has.
    func lastNoted(forTrigger triggerID: String) throws -> Loop? {
        var noted = FetchDescriptor<Loop>(
            predicate: #Predicate { $0.triggerID == triggerID && $0.note != nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
        )
        noted.fetchLimit = 1
        return try context.fetch(noted).first
    }

    /// The loops logged at or after `start`.
    func loops(since start: Date) throws -> [Loop] {
        try context.fetch(FetchDescriptor<Loop>(predicate: #Predicate { $0.createdAt >= start }))
    }
}
