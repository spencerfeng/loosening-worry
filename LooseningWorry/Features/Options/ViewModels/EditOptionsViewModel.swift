import Foundation
import Observation

/// The Edit options screen: one tab per step, listing the person's own options, the starters and what they removed,
/// with a card for adding one of their own. Options can't be renamed; to fix a typo, the person removes the option
/// and adds it again.
@Observable @MainActor
final class EditOptionsViewModel {
    /// The tab showing.
    private(set) var kind: OptionKind
    /// Whether the add card is open.
    private(set) var isAdding = false
    /// What the person has typed into the add card. Changing it clears any message about the last try; the text
    /// field writes the same text back now and then, which doesn't.
    var draft = "" {
        didSet {
            if draft != oldValue {
                addError = nil
            }
        }
    }

    /// Why the last try to add didn't, if it didn't.
    private(set) var addError: AddError?
    /// Why the last remove or restore didn't, if it didn't.
    private(set) var editError: EditError?

    enum EditError: Equatable {
        case removeFailed, restoreFailed
    }

    enum AddError: Equatable {
        case empty
        /// An option already shows this text.
        case alreadyShowing(String)
        /// A removed option has this text; restoring it keeps its history.
        case removed(String)
        case saveFailed
    }

    /// - Parameter kind: The tab to open on: the step the screen was opened from.
    init(kind: OptionKind = .trigger) {
        self.kind = kind
    }

    func select(_ kind: OptionKind) {
        self.kind = kind
        editError = nil
        cancelAdding()
    }

    /// Removes `choice` from the logger.
    /// - Parameter store: Saves the change. If it throws, `editError` tells the person nothing changed.
    func remove(_ choice: OptionChoice, store: (OptionChoice) throws -> Void) {
        do {
            try store(choice)
            editError = nil
        } catch {
            editError = .removeFailed
        }
    }

    /// Brings a removed `choice` back to the logger.
    /// - Parameter store: Saves the change. If it throws, `editError` tells the person nothing changed.
    func restore(_ choice: OptionChoice, store: (OptionChoice) throws -> Void) {
        do {
            try store(choice)
            editError = nil
        } catch {
            editError = .restoreFailed
        }
    }

    // MARK: - Sections

    /// The current tab's sections: the person's own, newest first; the starters, or step 3's core results; then
    /// what they removed. Empty sections are left out.
    func sections(saved: [LoopOption]) -> [EditSection] {
        let showing = OptionList.choices(for: kind, saved: saved)
        let starters = showing.filter { $0.starterID != nil }
        let ownOldestFirst = showing.filter { $0.starterID == nil }
        // The logger lists results oldest first; this screen lists everything newest first.
        let own = kind == .result ? ownOldestFirst.reversed() : ownOldestFirst
        let removed = OptionList.removedChoices(for: kind, saved: saved)
        let showingTexts = Set(showing.map(\.label))

        var sections: [EditSection] = []
        if !own.isEmpty {
            sections.append(EditSection(
                kind: .yourOwn,
                rows: own.map { EditRow(choice: $0, note: nil, action: .remove) },
            ))
        }
        if kind == .result {
            let rows = starters.map { EditRow(choice: $0, note: .coreResult, action: .locked) }
            sections.append(EditSection(kind: .coreResults, rows: rows))
        } else if !starters.isEmpty {
            sections.append(EditSection(
                kind: .starters,
                rows: starters.map { EditRow(choice: $0, note: nil, action: .remove) },
            ))
        }
        if !removed.isEmpty {
            let rows = removed.map { choice in
                EditRow(
                    choice: choice,
                    note: choice.starterID == nil ? .yourOwn : .starter,
                    action: .restore(isEnabled: !showingTexts.contains(choice.label)),
                )
            }
            sections.append(EditSection(kind: .removed(count: removed.count), rows: rows))
        }
        return sections
    }

    // MARK: - Adding

    func startAdding() {
        isAdding = true
        draft = ""
    }

    func cancelAdding() {
        isAdding = false
        draft = ""
    }

    /// Adds the draft, trimmed, as one of the person's own options for this tab. Text that matches an option exactly,
    /// case included, isn't added twice: one showing says so, and one removed asks to be restored instead.
    /// - Parameter save: Stores the new option's text.
    func add(saved: [LoopOption], save: (String) throws -> Void) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            addError = .empty
        } else if OptionList.match(text, in: OptionList.choices(for: kind, saved: saved)) != nil {
            addError = .alreadyShowing(text)
        } else if OptionList.match(text, in: OptionList.removedChoices(for: kind, saved: saved)) != nil {
            addError = .removed(text)
        } else {
            do {
                try save(text)
                cancelAdding()
            } catch {
                addError = .saveFailed
            }
        }
    }
}

/// One section of the Edit options screen.
struct EditSection: Equatable {
    enum Kind: Hashable {
        case yourOwn, starters, coreResults
        case removed(count: Int)
    }

    let kind: Kind
    let rows: [EditRow]
}

/// One option on the Edit options screen, with what the person can do to it.
struct EditRow: Equatable {
    enum Note: Equatable {
        case starter, yourOwn, coreResult
    }

    enum Action: Equatable {
        case remove
        /// A core result: it always shows.
        case locked
        case restore(isEnabled: Bool)
    }

    let choice: OptionChoice
    let note: Note?
    let action: Action

    var label: String {
        choice.label
    }
}
