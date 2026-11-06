import Foundation

/// When the person noticed the loop: the logger's "When did you notice?". Noticing earlier is how progress shows:
/// afterwards, then while it was happening, then meeting the urge with a tool before the habit runs.
///
/// The raw value is what a loop stores, so it never changes once released.
enum NoticeTiming: String, CaseIterable, Sendable {
    case afterwards
    case whileHappening
}

extension NoticeTiming {
    /// The answer's words, on the logger's chips and Insights' key.
    var label: LocalizedStringResource {
        switch self {
        case .afterwards: LocalizedStringResource("log.noticed.afterwards", defaultValue: "Afterwards")
        case .whileHappening:
            LocalizedStringResource("log.noticed.whileHappening", defaultValue: "While it was happening")
        }
    }
}
