import Foundation

/// What a core result says about how a loop went, for Insights to tell what a habit gives.
extension StarterID {
    /// Whether the result says how it went: every core result but "Not sure". Not a result at all is neither.
    var isClearResult: Bool {
        switch self {
        case .moreWorry, .tenseAndTired, .nothingChanged, .littleRelief, .actuallyHelped: true
        default: false
        }
    }

    /// The results that mean the habit didn't pay off: more worry, tension, or no change.
    var isUnrewardingResult: Bool {
        switch self {
        case .moreWorry, .tenseAndTired, .nothingChanged: true
        default: false
        }
    }
}
