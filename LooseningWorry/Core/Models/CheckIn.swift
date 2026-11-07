import Foundation
import SwiftData

/// What the person answered in a check-in: how it felt overall, the words they picked for it, then what's having the
/// biggest impact on them, each in the order picked.
struct CheckInAnswer: Equatable, Sendable {
    let pleasantness: Pleasantness
    let feelings: [Feeling]
    var contexts: [OptionChoice] = []
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
    /// The contexts picked, by `OptionChoice.id`, in the order they were picked, like a loop's `triggerID`.
    var contextIDs: [String] = []
    /// Each context's text as shown when picked, matching `contextIDs` place for place, so it still reads right after
    /// the option is removed.
    var contextLabels: [String] = []

    init(_ answer: CheckInAnswer) {
        pleasantnessID = answer.pleasantness.rawValue
        feelingIDs = answer.feelings.map(\.rawValue)
        contextIDs = answer.contexts.map(\.id)
        contextLabels = answer.contexts.map(\.label)
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
