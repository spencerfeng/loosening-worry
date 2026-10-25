import Foundation

/// An option the logger offers before the person adds their own.
///
/// Starters live in code, not in SwiftData, so they translate, never duplicate across synced devices, and reach
/// everyone in an app update. A person's renames and removals are saved as `LoopOption` overrides keyed by `id`.
struct StarterOption: Sendable {
    /// Stable across rewordings and translations.
    let id: String
    let kind: OptionKind
    let label: LocalizedStringResource

    static func options(for kind: OptionKind) -> [StarterOption] {
        all.filter { $0.kind == kind }
    }

    static func with(id: String) -> StarterOption? {
        all.first { $0.id == id }
    }

    /// In the order the logger offers them.
    static let all: [StarterOption] = [
        // Mostly what the worry is about; a moment gets its own chip only when the moment is the hook.
        StarterOption(
            .trigger,
            "work",
            LocalizedStringResource("starter.trigger.work", defaultValue: "Work"),
        ),
        StarterOption(
            .trigger,
            "deadline",
            LocalizedStringResource("starter.trigger.deadline", defaultValue: "Deadline"),
        ),
        StarterOption(
            .trigger,
            "money",
            LocalizedStringResource("starter.trigger.money", defaultValue: "Money"),
        ),
        StarterOption(
            .trigger,
            "health",
            LocalizedStringResource("starter.trigger.health", defaultValue: "Health"),
        ),
        StarterOption(
            .trigger,
            "familyOrPartner",
            LocalizedStringResource("starter.trigger.familyOrPartner", defaultValue: "Family or partner"),
        ),
        StarterOption(
            .trigger,
            "socialPlans",
            LocalizedStringResource("starter.trigger.socialPlans", defaultValue: "Social plans"),
        ),
        StarterOption(
            .trigger,
            "news",
            LocalizedStringResource("starter.trigger.news", defaultValue: "News"),
        ),
        StarterOption(
            .trigger,
            "waitingForReply",
            LocalizedStringResource("starter.trigger.waitingForReply", defaultValue: "Waiting for a reply"),
        ),
        StarterOption(
            .trigger,
            "tryingToSleep",
            LocalizedStringResource("starter.trigger.tryingToSleep", defaultValue: "Trying to sleep"),
        ),
        StarterOption(
            .trigger,
            "outOfNowhere",
            LocalizedStringResource("starter.trigger.outOfNowhere", defaultValue: "Out of nowhere"),
        ),

        // The most common worry habits first: new users see behaviors in this order.
        StarterOption(
            .behavior,
            "overthought",
            LocalizedStringResource("starter.behavior.overthought", defaultValue: "Overthought it"),
        ),
        StarterOption(
            .behavior,
            "keptChecking",
            LocalizedStringResource("starter.behavior.keptChecking", defaultValue: "Kept checking"),
        ),
        StarterOption(
            .behavior,
            "askedForReassurance",
            LocalizedStringResource("starter.behavior.askedForReassurance", defaultValue: "Asked for reassurance"),
        ),
        StarterOption(
            .behavior,
            "searchedOnline",
            LocalizedStringResource("starter.behavior.searchedOnline", defaultValue: "Searched online"),
        ),
        StarterOption(
            .behavior,
            "avoidedIt",
            LocalizedStringResource("starter.behavior.avoidedIt", defaultValue: "Avoided it"),
        ),
        StarterOption(
            .behavior,
            "putItOff",
            LocalizedStringResource("starter.behavior.putItOff", defaultValue: "Put it off"),
        ),
        StarterOption(
            .behavior,
            "overPrepared",
            LocalizedStringResource("starter.behavior.overPrepared", defaultValue: "Over-prepared"),
        ),
        StarterOption(
            .behavior,
            "scrolled",
            LocalizedStringResource("starter.behavior.scrolled", defaultValue: "Scrolled"),
        ),
        StarterOption(
            .behavior,
            "snacked",
            LocalizedStringResource("starter.behavior.snacked", defaultValue: "Snacked"),
        ),

        // Step 3's core results, worse to better so the list reads as a fair scale. Not sure isn't on the scale,
        // so it comes last.
        StarterOption(
            .result,
            "moreWorry",
            LocalizedStringResource("starter.result.moreWorry", defaultValue: "More worry"),
        ),
        StarterOption(
            .result,
            "tenseAndTired",
            LocalizedStringResource("starter.result.tenseAndTired", defaultValue: "Tense and tired"),
        ),
        StarterOption(
            .result,
            "nothingChanged",
            LocalizedStringResource("starter.result.nothingChanged", defaultValue: "Nothing changed"),
        ),
        StarterOption(
            .result,
            "littleRelief",
            LocalizedStringResource("starter.result.littleRelief", defaultValue: "A little relief"),
        ),
        StarterOption(
            .result,
            "actuallyHelped",
            LocalizedStringResource("starter.result.actuallyHelped", defaultValue: "It actually helped"),
        ),
        StarterOption(.result, "notSure", LocalizedStringResource("starter.result.notSure", defaultValue: "Not sure")),
    ]

    private init(_ kind: OptionKind, _ name: String, _ label: LocalizedStringResource) {
        id = "\(kind.rawValue).\(name)"
        self.kind = kind
        self.label = label
    }
}
