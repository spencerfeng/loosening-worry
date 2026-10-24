import Foundation
import SwiftData

/// Saves the options a person adds in the logger, as soon as they add them.
@MainActor
struct OptionStore {
    let context: ModelContext

    /// Adds `label` as the person's own option. If they hid an option that shows exactly this text, it comes back
    /// instead, so they never end up with a hidden option and a visible twin.
    func addOwn(_ label: String, kind: OptionKind) throws {
        let saved = try context.fetch(FetchDescriptor<LoopOption>())
        if let hidden = OptionList.hiddenOption(matching: label, for: kind, saved: saved) {
            hidden.isHidden = false
            hidden.updatedAt = .now
            // One of their own is listed by when it was added, so coming back puts it first, as a new one would be.
            // A starter keeps its place among the starters.
            if hidden.starterID == nil {
                hidden.createdAt = .now
            }
        } else {
            context.insert(LoopOption(kind: kind, label: label))
        }
        // Saved now rather than with the loop: the logger tells the person it's kept for next time.
        try context.save()
    }
}
