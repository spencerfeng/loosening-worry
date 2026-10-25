import Foundation
import SwiftData

/// Saves the options a person adds in the logger, as soon as they add them.
@MainActor
struct OptionStore {
    let context: ModelContext

    /// Adds `label` as the person's own option. If they hid an option that shows exactly this text, it comes back
    /// instead, so they never end up with a hidden option and a visible twin.
    /// - Returns: The choice to pick, with the id a loop counts it by: the new option's, or the one brought back.
    func addOwn(_ label: String, kind: OptionKind) throws -> OptionChoice {
        let saved = try context.fetch(FetchDescriptor<LoopOption>())
        let choice: OptionChoice
        if let hidden = OptionList.hiddenOption(matching: label, for: kind, saved: saved) {
            hidden.isHidden = false
            hidden.updatedAt = .now
            // One of their own is listed by when it was added. On steps 1 and 2, newest first, so coming back puts it
            // first, as a new one would be. Step 3 keeps the order they were added, so a result keeps its place. A
            // starter keeps its place among the starters.
            if hidden.starterID == nil, hidden.kind != .result {
                hidden.createdAt = .now
            }
            // A starter is counted by its id; one of their own by its option id.
            choice = OptionChoice(id: hidden.starterID ?? hidden.optionID, label: label)
        } else {
            let option = LoopOption(kind: kind, label: label)
            context.insert(option)
            choice = OptionChoice(option)
        }
        // Saved now rather than with the loop: the logger tells the person it's kept for next time.
        try context.save()
        return choice
    }
}
