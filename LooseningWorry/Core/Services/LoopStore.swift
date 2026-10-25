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
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        let start = week.start
        let loops = FetchDescriptor<Loop>(predicate: #Predicate { $0.createdAt >= start && $0.createdAt <= now })
        return try context.fetchCount(loops)
    }
}
