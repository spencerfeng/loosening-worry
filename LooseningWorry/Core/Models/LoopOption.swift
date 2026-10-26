import Foundation
import SwiftData

enum OptionKind: String, Codable, CaseIterable {
    case trigger, behavior, result
}

/// A trigger, behavior or result the person added, or their change to a starter.
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
        "custom." + UUID().uuidString
    }
}
