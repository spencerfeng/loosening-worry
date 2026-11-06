import Foundation

/// When the person noticed the loop: the logger's "When did you notice?". Noticing earlier is how progress shows.
///
/// The raw value is what a loop stores, so it never changes once released. The cases' order is the comparison: they run
/// from latest to earliest, so a greater timing is an earlier one.
enum NoticeTiming: String, CaseIterable, Comparable, Sendable {
    case afterwards
    case partway
    case asItStarted

    static func < (lhs: NoticeTiming, rhs: NoticeTiming) -> Bool {
        // Every case is in `allCases`, so neither index is ever missing.
        (allCases.firstIndex(of: lhs) ?? 0) < (allCases.firstIndex(of: rhs) ?? 0)
    }
}

extension NoticeTiming {
    /// The answer's words, on the logger's chips and Insights' key.
    var label: LocalizedStringResource {
        switch self {
        case .afterwards: LocalizedStringResource("log.noticed.afterwards", defaultValue: "Afterwards")
        case .partway: LocalizedStringResource("log.noticed.partway", defaultValue: "Partway through")
        case .asItStarted: LocalizedStringResource("log.noticed.asItStarted", defaultValue: "As it started")
        }
    }
}
