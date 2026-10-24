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
        StarterOption(
            .trigger,
            "workEmail",
            LocalizedStringResource("starter.trigger.workEmail", defaultValue: "Work email"),
        ),
        StarterOption(.trigger, "news", LocalizedStringResource("starter.trigger.news", defaultValue: "News")),
        StarterOption(
            .trigger,
            "deadline",
            LocalizedStringResource("starter.trigger.deadline", defaultValue: "Deadline"),
        ),
        StarterOption(.trigger, "bedtime", LocalizedStringResource("starter.trigger.bedtime", defaultValue: "Bedtime")),
        StarterOption(
            .trigger,
            "socialPlans",
            LocalizedStringResource("starter.trigger.socialPlans", defaultValue: "Social plans"),
        ),
        StarterOption(.trigger, "money", LocalizedStringResource("starter.trigger.money", defaultValue: "Money")),
        StarterOption(.trigger, "health", LocalizedStringResource("starter.trigger.health", defaultValue: "Health")),
        StarterOption(
            .trigger,
            "waitingForReply",
            LocalizedStringResource("starter.trigger.waitingForReply", defaultValue: "Waiting for a reply"),
        ),

        StarterOption(
            .behavior,
            "overthinking",
            LocalizedStringResource("starter.behavior.overthinking", defaultValue: "Overthinking"),
        ),
        StarterOption(
            .behavior,
            "checkedPhone",
            LocalizedStringResource("starter.behavior.checkedPhone", defaultValue: "Checked phone"),
        ),
        StarterOption(
            .behavior,
            "avoidedIt",
            LocalizedStringResource("starter.behavior.avoidedIt", defaultValue: "Avoided it"),
        ),
        StarterOption(
            .behavior,
            "snacked",
            LocalizedStringResource("starter.behavior.snacked", defaultValue: "Snacked"),
        ),
        StarterOption(
            .behavior,
            "overPlanned",
            LocalizedStringResource("starter.behavior.overPlanned", defaultValue: "Over-planned"),
        ),
        StarterOption(
            .behavior,
            "scrolled",
            LocalizedStringResource("starter.behavior.scrolled", defaultValue: "Scrolled"),
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
            "littleRelief",
            LocalizedStringResource("starter.result.littleRelief", defaultValue: "A little relief"),
        ),
        StarterOption(
            .result,
            "actualAnswer",
            LocalizedStringResource("starter.result.actualAnswer", defaultValue: "An actual answer"),
        ),
        StarterOption(
            .result,
            "nothingChanged",
            LocalizedStringResource("starter.result.nothingChanged", defaultValue: "Nothing changed"),
        ),
        StarterOption(
            .result,
            "distracted",
            LocalizedStringResource("starter.result.distracted", defaultValue: "Distracted for a while"),
        ),
        StarterOption(
            .result,
            "restless",
            LocalizedStringResource("starter.result.restless", defaultValue: "Restless"),
        ),
        StarterOption(
            .result,
            "lostSleep",
            LocalizedStringResource("starter.result.lostSleep", defaultValue: "Lost sleep"),
        ),
    ]

    private init(_ kind: OptionKind, _ name: String, _ label: LocalizedStringResource) {
        id = "\(kind.rawValue).\(name)"
        self.kind = kind
        self.label = label
    }
}
