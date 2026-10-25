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
}
