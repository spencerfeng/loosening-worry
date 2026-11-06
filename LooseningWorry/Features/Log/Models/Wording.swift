import Foundation

/// A habit or a result as a sentence can word it: a starter, which the app's own sentences word in the current
/// language, or one the person added, in their words as logged.
enum Wording: Equatable {
    case starter(StarterID)
    case own(String)

    /// Decided by the id, as Insights counts: options can't be renamed, so a starter is the app's words even when a
    /// loop kept older ones, from another language or before an update reworded it.
    init(id: String, label: String) {
        self = StarterID(rawValue: id).map(Self.starter) ?? .own(label)
    }

    /// The words to show: a starter's current ones, or the person's.
    var text: String {
        switch self {
        case let .starter(starter): String(localized: starter.label)
        case let .own(text): text
        }
    }
}
