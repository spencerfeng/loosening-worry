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

    /// When the person noticed the latest loop set off by the trigger with id `triggerID`, among those where they said;
    /// `nil` if they never did.
    func lastNoticed(forTrigger triggerID: String) throws -> NoticeTiming? {
        var answered = FetchDescriptor<Loop>(
            predicate: #Predicate { $0.triggerID == triggerID && $0.noticedID != nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
        )
        answered.fetchLimit = 1
        return try context.fetch(answered).first?.noticed
    }

    /// The loops logged at or after `start`.
    func loops(since start: Date) throws -> [Loop] {
        try context.fetch(FetchDescriptor<Loop>(predicate: #Predicate { $0.createdAt >= start }))
    }
}
