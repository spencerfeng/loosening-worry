import Foundation
import os

/// The "+ Add your own" field, shared by the logger and the check-in: whether it's open, what's typed, and the last
/// text added that couldn't be saved to the person's list.
struct AddOwnDraft: Equatable {
    private(set) var isOpen = false
    /// What the person has typed.
    var text = ""
    /// Text just added and picked that couldn't be saved to the person's list, so the step can say so; `nil`
    /// otherwise. The step sets it once the pick is made, since picking can close the field.
    var unsavedLabel: String?

    /// Whether the text holds anything to add once spaces around it are trimmed.
    var canAdd: Bool {
        !trimmed.isEmpty
    }

    /// Opens or closes the field, starting it empty and dropping any note about the last one added.
    mutating func toggle() {
        isOpen.toggle()
        text = ""
        unsavedLabel = nil
    }

    /// Closes the field, dropping the text and any note about the last one added.
    mutating func close() {
        isOpen = false
        text = ""
        unsavedLabel = nil
    }

    /// Takes the text, trimmed, as the choice to pick, and closes the field. Text that matches a choice exactly, case
    /// included, gives that choice instead of saving a duplicate; blank text gives nothing and leaves the field open.
    /// - Parameters:
    ///   - existing: The choices the step shows now.
    ///   - save: Stores the text as one of the person's own and returns the choice to pick. If it throws, the text
    ///     comes back under an id of its own, unsaved, since what's logged keeps its own copy of the text.
    /// - Returns: The choice to pick, and whether it's on the person's list for next time.
    mutating func take(
        existing: [OptionChoice],
        save: (String) throws -> OptionChoice,
    ) -> (choice: OptionChoice, isSaved: Bool)? {
        guard canAdd else { return nil }
        let label = trimmed
        close()
        if let match = OptionList.match(label, in: existing) {
            return (match, true)
        }
        do {
            return try (save(label), true)
        } catch {
            Self.logger.error("Couldn't save an option the person added: \(error)")
            return (.unsavedOwn(label), false)
        }
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Options")
}
