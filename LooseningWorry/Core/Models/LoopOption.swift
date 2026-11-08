import Foundation
import SwiftData

/// What an option answers: one of a loop's three steps, or a check-in's context.
///
/// The raw value is what `LoopOption` stores, so it never changes once released.
enum OptionKind: String, CaseIterable, Sendable {
    case trigger, behavior, result
    /// What's having the biggest impact on the person, the check-in's last step.
    case context
    /// A kind from a newer version, read from a synced option. No list asks for it, so such options stay out of
    /// sight; see `init(from:)`.
    case unrecognized

    /// The kinds this version offers.
    static let allCases: [OptionKind] = [.trigger, .behavior, .result, .context]

    /// A loop's steps, in the logger's order.
    static let loopSteps: [OptionKind] = [.trigger, .behavior, .result]

    /// How a kind's choices are listed.
    enum ChoiceOrder {
        /// The person's own first, newest first, then the starters in their order.
        case ownNewestFirst
        /// The starters in their fixed order, then the person's own, oldest first, so step 3 never nudges the answer.
        case startersFirst
        /// The person's own and the starters together, alphabetical in the person's language.
        case alphabetical
    }

    var choiceOrder: ChoiceOrder {
        switch self {
        case .trigger, .behavior: .ownNewestFirst
        case .result: .startersFirst
        case .context: .alphabetical
        // Never listed, so any order does.
        case .unrecognized: .ownNewestFirst
        }
    }
}

extension OptionKind: Codable {
    /// SwiftData reads a stored kind through `Codable`, and a decoding failure crashes the fetch. A kind from a newer
    /// version reads as `unrecognized` instead, so every other option still loads. Kept on the enum rather than by
    /// storing text, since changing the stored type would migrate every saved kind back to the default.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: rawValue) ?? .unrecognized
    }

    /// Writing `unrecognized` back would replace the newer kind it stands in for, on every device. Nothing does: no
    /// list shows such an option, and changes reach only options a list showed.
    func encode(to encoder: Encoder) throws {
        assert(self != .unrecognized, "An option of an unrecognized kind was saved, replacing its newer kind")
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// A trigger, behavior, result or check-in context the person added, or their change to a starter.
///
/// With no `starterID` it is their own option. With one, it overrides that `StarterOption` to hide it from their list;
/// starters can't be renamed. It keeps the starter's full text, so adding that text again brings the starter back.
/// Starters themselves are never stored (see `StarterOption`).
///
/// When two devices each change the same starter, the override that `supersedes` the others wins.
@Model
final class LoopOption {
    var kind = OptionKind.trigger
    var label: String = ""
    var starterID: String?
    /// Stable across devices, so loops can count an option of the person's own by it. Overrides use `starterID`
    /// instead. Each init assigns a fresh one too: a schema default alone can give rows added by a migration the
    /// same value.
    var optionID: String = LoopOption.newOptionID()
    var isHidden: Bool = false
    var createdAt = Date.now
    var updatedAt = Date.now

    /// Whether this is the person's own option rather than a change to a starter.
    var isCustom: Bool {
        starterID == nil
    }

    /// Whether this change to a starter wins over `other`: the one edited last, and if both were edited at the same
    /// moment, the one created last, so every device picks the same one.
    func supersedes(_ other: LoopOption) -> Bool {
        (updatedAt, createdAt) > (other.updatedAt, other.createdAt)
    }

    /// The starter this overrides; `nil` for the person's own option, or for an override of a starter this version
    /// doesn't have, synced from a newer one.
    var starter: StarterID? {
        starterID.flatMap(StarterID.init(rawValue:))
    }

    /// The person's own option.
    init(kind: OptionKind, label: String) {
        optionID = Self.newOptionID()
        self.kind = kind
        self.label = label
    }

    /// A change to a starter, which hides or restores it. `label` keeps the text it showed.
    init(overriding starter: StarterID, label: String) {
        optionID = Self.newOptionID()
        kind = starter.kind
        self.label = label
        starterID = starter.rawValue
    }

    /// A fresh id for one of the person's own options.
    static func newOptionID() -> String {
        ownIDPrefix + UUID().uuidString
    }

    /// Whether `id` was made for one of the person's own options, rather than a starter, a tool or its outcome.
    static func isOwnID(_ id: String) -> Bool {
        id.hasPrefix(ownIDPrefix)
    }

    private static let ownIDPrefix = "custom."
}
