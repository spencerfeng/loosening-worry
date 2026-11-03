import Foundation
import SwiftData

/// Saves the person's check-ins.
@MainActor
struct CheckInStore {
    let context: ModelContext

    /// Adds `checkIn` and saves it now, so it's stored by the time the finish screen shows. If saving fails the
    /// check-in is taken out again, so trying once more doesn't add a second copy.
    func add(_ checkIn: CheckIn) throws {
        context.insert(checkIn)
        do {
            try context.save()
        } catch {
            context.delete(checkIn)
            throw error
        }
    }
}
