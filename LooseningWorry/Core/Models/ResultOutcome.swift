import Foundation

/// What a logged result says the habit gave: the groups Insights counts as "no better" and Nice catch's dots show, kept
/// in one place so the two never disagree.
enum ResultOutcome: Equatable {
    /// More worry, tension, or no change: the habit didn't pay off.
    case noBetter
    /// A little relief, or it helped.
    case relief
    /// Not sure, the person's own words, or not a result at all: it doesn't say how it went.
    case unclear

    init(resultID: String) {
        switch StarterID(rawValue: resultID) {
        case .moreWorry, .tenseAndTired, .nothingChanged: self = .noBetter
        case .littleRelief, .actuallyHelped: self = .relief
        default: self = .unclear
        }
    }
}
