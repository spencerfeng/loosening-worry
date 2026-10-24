import Foundation
import SwiftData

enum OptionKind: String, Codable {
    case trigger, behavior, result
}

/// A trigger, behavior or result the logger offers as a one-tap choice.
@Model
final class LoopOption {
    var kind = OptionKind.trigger
    var label: String = ""
    var isCustom: Bool = false
    var isHidden: Bool = false
    var createdAt = Date.now

    init(kind: OptionKind, label: String, isCustom: Bool) {
        self.kind = kind
        self.label = label
        self.isCustom = isCustom
    }
}
