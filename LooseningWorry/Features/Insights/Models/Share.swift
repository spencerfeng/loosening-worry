import Foundation

/// How many of something went a given way out of all of them, as Insights shows it in words ("no better 5 of 6 times",
/// "3 of 7 check-ins") and as a bar filled that far.
struct Share: Equatable {
    let count: Int
    let total: Int

    /// How much of a bar it fills: `count` out of `total`, or none when nothing has been counted yet.
    var fraction: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
}
