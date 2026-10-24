import Foundation

/// One choice the logger shows for a step.
struct OptionChoice: Equatable {
    let label: String
    /// Set when the choice is a starter, renamed or not.
    let starterID: String?
}

/// Combines the starters with what the person saved into the choices the logger shows.
enum OptionList {
    /// The person's own options come first, newest first, then the starters with their changes applied. Hidden
    /// options are left out, and each text (case included) appears only once, in its first place, so a starter
    /// matching one of their own appears as theirs.
    static func choices(for kind: OptionKind, saved: [LoopOption]) -> [OptionChoice] {
        let ofKind = saved.filter { $0.kind == kind }
        let all = customChoices(in: ofKind) + starterChoices(for: kind, overrides: newestOverrides(in: ofKind))
        var seen: Set<String> = []
        return all.filter { seen.insert($0.label).inserted }
    }

    private static func customChoices(in saved: [LoopOption]) -> [OptionChoice] {
        saved
            .filter { $0.starterID == nil && !$0.isHidden }
            .sorted { $0.createdAt > $1.createdAt }
            .map { OptionChoice(label: $0.label, starterID: nil) }
    }

    /// Two devices can each change the same starter before they sync; the one edited last wins, and if both were
    /// edited at the same moment, the one created last, so every device makes the same choice.
    private static func newestOverrides(in saved: [LoopOption]) -> [String: LoopOption] {
        var newest: [String: LoopOption] = [:]
        for option in saved {
            guard let starterID = option.starterID else { continue }
            if
                let current = newest[starterID],
                (current.updatedAt, current.createdAt) >= (option.updatedAt, option.createdAt)
            {
                continue
            }
            newest[starterID] = option
        }
        return newest
    }

    private static func starterChoices(for kind: OptionKind, overrides: [String: LoopOption]) -> [OptionChoice] {
        StarterOption.options(for: kind).compactMap { starter in
            let override = overrides[starter.id]
            if override?.isHidden == true {
                return nil
            }
            return OptionChoice(label: override?.label ?? String(localized: starter.label), starterID: starter.id)
        }
    }
}
