import Foundation
import SwiftData

/// Saves the person's changes to their options as soon as they make them: options they add in the logger, and ones
/// they remove and restore on the Edit options screen.
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
            bringBack(hidden)
            // A starter is counted by its id; one of their own by its option id.
            choice = OptionChoice(id: hidden.starterID ?? hidden.optionID, label: label)
        } else {
            let option = LoopOption(kind: kind, label: label)
            context.insert(option)
            choice = OptionChoice(option)
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
    }

    /// Removes `choice` from the logger: hides every option showing its text. A starter gets a change that hides it,
    /// keeping its full text so typing it again brings it back. Past loops keep it either way.
    /// - Throws: `EditError.coreResult` for a core result, which can't be removed.
    func remove(_ choice: OptionChoice) throws {
        if Self.ids(of: choice).contains(where: { StarterID(rawValue: $0)?.kind == .result }) {
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

    private static func ids(of choice: OptionChoice) -> [String] {
        [choice.id] + choice.mergedIDs
    }

    /// Calls `starter` for each starter `choice` shows, and `own` for each of the person's own options it shows.
    private func forEachOption(
        showing choice: OptionChoice,
        in saved: [LoopOption],
        starter: (StarterID) -> Void,
        own: (LoopOption) -> Void,
    ) {
        for id in Self.ids(of: choice) {
            if let starterID = StarterID(rawValue: id) {
                starter(starterID)
            } else if let option = saved.first(where: { $0.optionID == id }) {
                own(option)
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
        // One of their own is listed by when it was added. On steps 1 and 2, newest first, so coming back puts it
        // first, as a new one would be. Step 3 keeps the order they were added, so a result keeps its place. A starter
        // keeps its place among the starters.
        if option.isCustom, option.kind != .result {
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
