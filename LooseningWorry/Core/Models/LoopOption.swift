import Foundation
import SwiftData

enum OptionKind: String, Codable, CaseIterable {
    case trigger, behavior, result
}

/// A trigger, behavior or result the person added, or their change to a starter.
///
/// With no `starterID` it is their own option. With one, it overrides that `StarterOption`: `label` renames it and
/// `isHidden` removes it. Starters themselves are never stored (see `StarterOption`).
///
/// When two devices each change the same starter, the override with the newest `updatedAt` wins (see `OptionList`).
@Model
final class LoopOption {
    var kind = OptionKind.trigger
    var label: String = ""
    var starterID: String?
    var isHidden: Bool = false
    var createdAt = Date.now
    var updatedAt = Date.now

    init(kind: OptionKind, label: String, starterID: String? = nil) {
        self.kind = kind
        self.label = label
        self.starterID = starterID
    }
}
