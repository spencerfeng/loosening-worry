import Foundation

/// Names one starter. Only these ids exist, so app code can't refer to a starter that isn't there.
///
/// The cases are in the order the logger offers them. The raw value is what's stored on overrides and loops, so it
/// never changes once released.
enum StarterID: String, CaseIterable, Sendable {
    // Mostly what the worry is about; a moment gets its own chip only when the moment is the hook.
    case work = "trigger.work"
    case deadline = "trigger.deadline"
    case money = "trigger.money"
    case health = "trigger.health"
    case familyOrPartner = "trigger.familyOrPartner"
    case socialPlans = "trigger.socialPlans"
    case news = "trigger.news"
    case waitingForReply = "trigger.waitingForReply"
    case tryingToSleep = "trigger.tryingToSleep"
    case outOfNowhere = "trigger.outOfNowhere"

    // The most common worry habits first: new users see behaviors in this order.
    case overthought = "behavior.overthought"
    case keptChecking = "behavior.keptChecking"
    case askedForReassurance = "behavior.askedForReassurance"
    case searchedOnline = "behavior.searchedOnline"
    case avoidedIt = "behavior.avoidedIt"
    case putItOff = "behavior.putItOff"
    case overPrepared = "behavior.overPrepared"
    case scrolled = "behavior.scrolled"
    case snacked = "behavior.snacked"

    // Step 3's core results, worse to better so the list reads as a fair scale. Not sure isn't on the scale, so it
    // comes last.
    case moreWorry = "result.moreWorry"
    case tenseAndTired = "result.tenseAndTired"
    case nothingChanged = "result.nothingChanged"
    case littleRelief = "result.littleRelief"
    case actuallyHelped = "result.actuallyHelped"
    case notSure = "result.notSure"

    /// The step the starter belongs to, read from the id's prefix.
    var kind: OptionKind {
        guard let kind = OptionKind(rawValue: String(rawValue.prefix { $0 != "." })) else {
            preconditionFailure("Starter id \(rawValue) doesn't start with a kind")
        }
        return kind
    }

    /// The text the starter shows, translated. The catalog key is spelled out so the compiler can extract it.
    var label: LocalizedStringResource {
        switch self {
        case .work: LocalizedStringResource("starter.trigger.work", defaultValue: "Work")
        case .deadline: LocalizedStringResource("starter.trigger.deadline", defaultValue: "Deadline")
        case .money: LocalizedStringResource("starter.trigger.money", defaultValue: "Money")
        case .health: LocalizedStringResource("starter.trigger.health", defaultValue: "Health")
        case .familyOrPartner:
            LocalizedStringResource("starter.trigger.familyOrPartner", defaultValue: "Family or partner")
        case .socialPlans: LocalizedStringResource("starter.trigger.socialPlans", defaultValue: "Social plans")
        case .news: LocalizedStringResource("starter.trigger.news", defaultValue: "News")
        case .waitingForReply:
            LocalizedStringResource("starter.trigger.waitingForReply", defaultValue: "Waiting for a reply")
        case .tryingToSleep: LocalizedStringResource("starter.trigger.tryingToSleep", defaultValue: "Trying to sleep")
        case .outOfNowhere: LocalizedStringResource("starter.trigger.outOfNowhere", defaultValue: "Out of nowhere")
        case .overthought: LocalizedStringResource("starter.behavior.overthought", defaultValue: "Overthought it")
        case .keptChecking: LocalizedStringResource("starter.behavior.keptChecking", defaultValue: "Kept checking")
        case .askedForReassurance:
            LocalizedStringResource("starter.behavior.askedForReassurance", defaultValue: "Asked for reassurance")
        case .searchedOnline:
            LocalizedStringResource("starter.behavior.searchedOnline", defaultValue: "Searched online")
        case .avoidedIt: LocalizedStringResource("starter.behavior.avoidedIt", defaultValue: "Avoided it")
        case .putItOff: LocalizedStringResource("starter.behavior.putItOff", defaultValue: "Put it off")
        case .overPrepared: LocalizedStringResource("starter.behavior.overPrepared", defaultValue: "Over-prepared")
        case .scrolled: LocalizedStringResource("starter.behavior.scrolled", defaultValue: "Scrolled")
        case .snacked: LocalizedStringResource("starter.behavior.snacked", defaultValue: "Snacked")
        case .moreWorry: LocalizedStringResource("starter.result.moreWorry", defaultValue: "More worry")
        case .tenseAndTired: LocalizedStringResource("starter.result.tenseAndTired", defaultValue: "Tense and tired")
        case .nothingChanged: LocalizedStringResource("starter.result.nothingChanged", defaultValue: "Nothing changed")
        case .littleRelief: LocalizedStringResource("starter.result.littleRelief", defaultValue: "A little relief")
        case .actuallyHelped:
            LocalizedStringResource("starter.result.actuallyHelped", defaultValue: "It actually helped")
        case .notSure: LocalizedStringResource("starter.result.notSure", defaultValue: "Not sure")
        }
    }
}

/// An option the logger offers before the person adds their own.
///
/// Starters live in code, not in SwiftData, so they translate, never duplicate across synced devices, and reach
/// everyone in an app update. A person's removals are saved as `LoopOption` overrides keyed by `id`.
struct StarterOption: Sendable {
    let id: StarterID

    var kind: OptionKind {
        id.kind
    }

    var label: LocalizedStringResource {
        id.label
    }

    /// The label in the person's language.
    var text: String {
        String(localized: label)
    }

    /// In the order the logger offers them.
    static let all = StarterID.allCases.map(StarterOption.init)

    static func options(for kind: OptionKind) -> [StarterOption] {
        all.filter { $0.kind == kind }
    }

    static func with(id: StarterID) -> StarterOption {
        StarterOption(id: id)
    }
}
