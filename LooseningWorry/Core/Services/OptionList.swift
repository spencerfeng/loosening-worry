import Foundation

/// One choice the logger shows for a step.
struct OptionChoice: Equatable {
    /// What a loop stores to count this choice by: the starter's id, or the `optionID` of the person's own option.
    let id: String
    let label: String
    /// The ids of other options showing this same text, which the list shows once: copies synced from two devices,
    /// or a starter and one of the person's own. Loops logged with any of them count as this choice.
    var mergedIDs: [String] = []

    /// Set when the choice is a starter.
    var starterID: StarterID? {
        StarterID(rawValue: id)
    }

    init(_ starter: StarterID, label: String) {
        self.init(id: starter.rawValue, label: label)
    }

    init(id: String, label: String) {
        self.id = id
        self.label = label
    }

    /// Text of the person's own that couldn't be saved as an option. It gets an id of its own, matching no option, so
    /// the loop still has something to be counted by.
    static func unsavedOwn(_ label: String) -> OptionChoice {
        OptionChoice(id: LoopOption.newOptionID(), label: label)
    }

    /// One of the person's own options.
    init(_ option: LoopOption) {
        self.init(id: option.optionID, label: option.label)
    }
}

/// Combines the starters with what the person saved into the choices the logger shows.
enum OptionList {
    /// The person's own options come first, newest first, then the starters the person hasn't hidden, each in its own
    /// words: options can't be renamed. Results are
    /// the exception: step 3 never nudges the answer, so its core results always lead, in their fixed order, and the
    /// person's own follow in the order they were added. Hidden options are left out, and each text (case included)
    /// appears only once, in its first place, so a starter matching one of their own appears as theirs on steps 1
    /// and 2, and as the starter on step 3. The ids of the copies left out go into the shown choice's `mergedIDs`.
    static func choices(for kind: OptionKind, saved: [LoopOption]) -> [OptionChoice] {
        let ofKind = saved.filter { $0.kind == kind }
        let starters = starterChoices(for: kind, overrides: winningOverrides(in: ofKind))
        let custom = customChoicesOldestFirst(in: ofKind)
        let all = switch kind {
        case .trigger, .behavior: custom.reversed() + starters
        case .result: starters + custom
        }
        var shown: [OptionChoice] = []
        var placeOfLabel: [String: Int] = [:]
        for choice in all {
            if let place = placeOfLabel[choice.label] {
                shown[place].mergedIDs.append(choice.id)
            } else {
                placeOfLabel[choice.label] = shown.count
                shown.append(choice)
            }
        }
        return shown
    }

    /// The choice showing exactly `typed`, once spaces around it are trimmed: case and inner spaces count. The logger's
    /// add-your-own and the Edit options screen both check new text with it, so neither saves a twin.
    static func match(_ typed: String, in choices: [OptionChoice]) -> OptionChoice? {
        let text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        return choices.first { $0.label == text }
    }

    /// The hidden option of this kind that would show exactly this text if it came back: one of the person's own,
    /// or a starter whose newest change hides it. A hidden option keeps its full text, so that text is what matches.
    static func hiddenOption(matching label: String, for kind: OptionKind, saved: [LoopOption]) -> LoopOption? {
        let ofKind = saved.filter { $0.kind == kind }
        if let custom = ofKind.first(where: { $0.isCustom && $0.isHidden && $0.label == label }) {
            return custom
        }
        return winningOverrides(in: ofKind).values.first { $0.isHidden && $0.label == label }
    }

    /// The options the person removed, newest removed first: their own, and starters whose newest change hides them.
    /// Each text appears once, with the ids of its other copies in `mergedIDs`, so restoring it brings all back.
    static func removedChoices(for kind: OptionKind, saved: [LoopOption]) -> [OptionChoice] {
        let ofKind = saved.filter { $0.kind == kind }
        let removedStarters = winningOverrides(in: ofKind).values.compactMap { override -> (OptionChoice, Date)? in
            guard override.isHidden, let starter = override.starter else { return nil }
            return (OptionChoice(starter, label: StarterOption.with(id: starter).text), override.updatedAt)
        }
        let removedOwn = ofKind.filter { $0.isCustom && $0.isHidden }.map { (OptionChoice($0), $0.updatedAt) }
        var shown: [OptionChoice] = []
        var placeOfLabel: [String: Int] = [:]
        for (choice, _) in (removedStarters + removedOwn).sorted(by: { $0.1 > $1.1 }) {
            if let place = placeOfLabel[choice.label] {
                shown[place].mergedIDs.append(choice.id)
            } else {
                placeOfLabel[choice.label] = shown.count
                shown.append(choice)
            }
        }
        return shown
    }

    private static func customChoicesOldestFirst(in saved: [LoopOption]) -> [OptionChoice] {
        saved
            .filter { $0.isCustom && !$0.isHidden }
            .sorted { $0.createdAt < $1.createdAt }
            .map(OptionChoice.init)
    }

    /// Two devices can each change the same starter before they sync; the change that supersedes the others wins.
    static func winningOverrides(in saved: [LoopOption]) -> [String: LoopOption] {
        var newest: [String: LoopOption] = [:]
        for option in saved {
            guard let starterID = option.starterID else { continue }
            if let current = newest[starterID], !option.supersedes(current) {
                continue
            }
            newest[starterID] = option
        }
        return newest
    }

    private static func starterChoices(for kind: OptionKind, overrides: [String: LoopOption]) -> [OptionChoice] {
        StarterOption.options(for: kind).compactMap { starter in
            if overrides[starter.id.rawValue]?.isHidden == true {
                return nil
            }
            return OptionChoice(starter.id, label: starter.text)
        }
    }
}
