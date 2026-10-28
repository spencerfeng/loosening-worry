import Foundation
import SwiftData

/// A kind phrase the person kept from Be kind, or their own words, to read again. It keeps the words as they were,
/// so rewording a phrase later never changes one already kept.
@Model
final class KeptPhrase {
    var text: String = ""
    var keptAt = Date.now

    init(text: String, keptAt: Date) {
        self.text = text
        self.keptAt = keptAt
    }
}
