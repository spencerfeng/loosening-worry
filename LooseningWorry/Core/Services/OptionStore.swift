import Foundation
import SwiftData

/// Saves the person's changes to their options as soon as they make them: options they add in the logger, and ones
/// they remove and restore on the Edit options screen.
@MainActor
struct OptionStore {
    let context: ModelContext

    /// Adds `typed`, trimmed, as the person's own option. If they hid an option that shows exactly this text, it comes
    /// back
    /// instead, so they never end up with a hidden option and a visible twin. If they deleted one, it comes back
    /// under its old ids, so what was logged with it before counts with it again.
    /// - Returns: The choice to pick, with the id a loop counts it by: the new option's, or the one brought back.
    func addOwn(_ typed: String, kind: OptionKind) throws -> OptionChoice {
        // Trimmed as `OptionList.match` trims, so every check below sees the text as it will show.
        let label = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved = try context.fetch(FetchDescriptor<LoopOption>())
        let choice: OptionChoice
        if let hidden = OptionList.hiddenOption(matching: label, for: kind, saved: saved) {
            bringBack(hidden)
            // A starter is counted by its id; one of their own by its option id.
            choice = OptionChoice(id: hidden.starterID ?? hidden.optionID, label: label)
        } else {
            let deletedIDs = try deletedIDs(showing: label, for: kind, saved: saved)
            let options = (deletedIDs.isEmpty ? [LoopOption.newOptionID()] : deletedIDs).map { id in
                let option = LoopOption(kind: kind, label: label)
                option.optionID = id
                return option
            }
            options.forEach(context.insert)
            choice = OptionChoice(options[0])
        }
        // Saved now rather than with the loop: the logger tells the person it's kept for next time.
        try saveOrRollBack()
        return choice
    }

    enum EditError: Error, Equatable {
        /// Step 3's core results always show, so the scale reads the same every time.
        case coreResult
        /// Another option already shows this text, so restoring would list it twice.
        case alreadyShowing
        /// Starters live in code, so they can be hidden but not deleted.
        case starter
    }

    /// Removes `choice` from the logger: hides every option showing its text. A starter gets a change that hides it,
    /// keeping its full text so typing it again brings it back. Past loops keep it either way.
    /// - Throws: `EditError.coreResult` for a core result, which can't be removed.
    func remove(_ choice: OptionChoice) throws {
        if choice.allIDs.contains(where: { StarterID(rawValue: $0)?.kind == .result }) {
            throw EditError.coreResult
        }
        let saved = try context.fetch(FetchDescriptor<LoopOption>())
        forEachOption(showing: choice, in: saved) { starter in
            setHidden(true, starter: starter, saved: saved)
        } own: { own in
            own.isHidden = true
            own.updatedAt = .now
        }
        try saveOrRollBack()
    }

    /// Brings a removed `choice` back to the logger, with every copy of its text.
    /// - Throws: `EditError.alreadyShowing` if another option now shows the same text.
    func restore(_ choice: OptionChoice, kind: OptionKind) throws {
        let saved = try context.fetch(FetchDescriptor<LoopOption>())
        if OptionList.match(choice.label, in: OptionList.choices(for: kind, saved: saved)) != nil {
            throw EditError.alreadyShowing
        }
        forEachOption(showing: choice, in: saved) { starter in
            setHidden(false, starter: starter, saved: saved)
        } own: { own in
            bringBack(own)
        }
        try saveOrRollBack()
    }

    /// Deletes a removed `choice` of the person's own for good, every copy of its text included. Past loops and
    /// check-ins keep its text, and adding the text again later counts them with it (see `addOwn`).
    /// - Throws: `EditError.starter` if the choice shows a starter.
    func delete(_ choice: OptionChoice) throws {
        if choice.showsStarter {
            throw EditError.starter
        }
        let ids = Set(choice.allIDs)
        for option in try context.fetch(FetchDescriptor<LoopOption>()) where ids.contains(option.optionID) {
            context.delete(option)
        }
        try saveOrRollBack()
    }

    /// The ids of the person's own options of `kind` that showed `label` and were deleted, as the loops or check-ins
    /// logged with them still hold them: ids made for an option of their own that no option has now. Starters, tools
    /// and tool outcomes have ids of their own kinds, never taken.
    private func deletedIDs(showing label: String, for kind: OptionKind, saved: [LoopOption]) throws -> [String] {
        let logged: [OptionChoice] = switch kind {
        case .context: try context.fetch(FetchDescriptor<CheckIn>()).flatMap(\.contexts)
        default: try context.fetch(FetchDescriptor<Loop>()).compactMap { $0.answer(for: kind) }
        }
        let taken = Set(saved.map(\.optionID))
        var ids: [String] = []
        for entry in logged where entry.label == label {
            if LoopOption.isOwnID(entry.id), !taken.contains(entry.id), !ids.contains(entry.id) {
                ids.append(entry.id)
            }
        }
        return ids
    }

    /// Calls `starter` for each starter `choice` shows, and `own` for each of the person's own options it shows.
    private func forEachOption(
        showing choice: OptionChoice,
        in saved: [LoopOption],
        starter: (StarterID) -> Void,
        own: (LoopOption) -> Void,
    ) {
        for id in choice.allIDs {
            if let starterID = StarterID(rawValue: id) {
                starter(starterID)
            } else {
                // Two devices can each have brought a deleted option back under its old id.
                saved.filter { $0.optionID == id }.forEach(own)
            }
        }
    }

    /// Saves now, or, if that fails, drops the unsaved changes so the screen goes back to what's stored.
    private func saveOrRollBack() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Shows a hidden option again, as a change made now so it wins across devices.
    private func bringBack(_ option: LoopOption) {
        option.isHidden = false
        option.updatedAt = .now
        // Where it's listed newest first, coming back puts it first, as a new one would be. Step 3 keeps the order
        // they were added, so a result keeps its place; contexts are alphabetical. A starter keeps its place among the
        // starters.
        if option.isCustom, option.kind.choiceOrder == .ownNewestFirst {
            option.createdAt = .now
        }
    }

    /// Hides or shows a starter by changing the change that wins, or adding one if it has none. It stores the
    /// starter's own words, since options can't be renamed, so a hidden starter is found by the text it shows.
    private func setHidden(_ isHidden: Bool, starter: StarterID, saved: [LoopOption]) {
        let text = StarterOption.with(id: starter).text
        if let winning = OptionList.winningOverrides(in: saved)[starter.rawValue] {
            winning.isHidden = isHidden
            winning.label = text
            winning.updatedAt = .now
        } else {
            let override = LoopOption(overriding: starter, label: text)
            override.isHidden = isHidden
            context.insert(override)
        }
    }
}
