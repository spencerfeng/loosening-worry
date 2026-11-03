import Foundation
import SwiftData

/// What the person answered in a check-in: how it felt overall, then the words they picked for it, in order.
struct CheckInAnswer: Equatable, Sendable {
    let pleasantness: Pleasantness
    let feelings: [Feeling]
}

/// One check-in, as saved.
@Model
final class CheckIn {
    var createdAt = Date.now
    /// How it felt overall, by `Pleasantness` id. Kept as text like `feelingIDs`, so a check-in synced from a newer
    /// version with a step this one doesn't know still loads.
    var pleasantnessID: String = Pleasantness.neutral.rawValue
    /// The words picked, by `Feeling` id, in the order they were picked.
    var feelingIDs: [String] = []

    init(_ answer: CheckInAnswer) {
        pleasantnessID = answer.pleasantness.rawValue
        feelingIDs = answer.feelings.map(\.rawValue)
    }

    /// How it felt overall, or `nil` for a step this version doesn't know.
    var pleasantness: Pleasantness? {
        Pleasantness(rawValue: pleasantnessID)
    }

    /// The words picked that this version knows.
    var feelings: [Feeling] {
        feelingIDs.compactMap(Feeling.init(rawValue:))
    }
}
