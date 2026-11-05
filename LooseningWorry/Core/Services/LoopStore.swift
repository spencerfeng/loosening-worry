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

    /// How many loops were logged this calendar week, from its first day in `calendar` up to `now`.
    func loopsThisWeek(now: Date = .now, calendar: Calendar = .current) throws -> Int {
        guard let start = calendar.startOfWeek(containing: now) else { return 0 }
        let loops = FetchDescriptor<Loop>(predicate: #Predicate { $0.createdAt >= start && $0.createdAt <= now })
        return try context.fetchCount(loops)
    }

    /// When the person noticed the latest habit set off by the trigger with id `triggerID`, among those where they
    /// said;
    /// `nil` if they never did. Loops met with a tool are left out: choosing a tool is noticing the urge as it started,
    /// so comparing with one would leave the next habit nothing to improve on.
    func lastNoticed(forTrigger triggerID: String) throws -> NoticeTiming? {
        let toolPrefix = QuickTool.behaviorIDPrefix
        var answered = FetchDescriptor<Loop>(
            predicate: #Predicate {
                $0.triggerID == triggerID && $0.noticedID != nil && !$0.behaviorID.starts(with: toolPrefix)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
        )
        answered.fetchLimit = 1
        return try context.fetch(answered).first?.noticed
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
