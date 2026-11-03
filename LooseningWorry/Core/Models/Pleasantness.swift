import Foundation

/// How a feeling is overall, the check-in's first question: State of Mind's seven steps, unpleasant to pleasant.
///
/// The raw value is what a check-in stores, so it never changes once released.
enum Pleasantness: String, CaseIterable, Codable, Sendable {
    case veryUnpleasant
    case unpleasant
    case slightlyUnpleasant
    case neutral
    case slightlyPleasant
    case pleasant
    case veryPleasant

    /// Whether the step is below neutral.
    var isUnpleasant: Bool {
        switch self {
        case .veryUnpleasant, .unpleasant, .slightlyUnpleasant: true
        case .neutral, .slightlyPleasant, .pleasant, .veryPleasant: false
        }
    }

    /// The step as the check-in shows it, translated.
    var label: LocalizedStringResource {
        switch self {
        case .veryUnpleasant: LocalizedStringResource("pleasantness.veryUnpleasant", defaultValue: "Very unpleasant")
        case .unpleasant: LocalizedStringResource("pleasantness.unpleasant", defaultValue: "Unpleasant")
        case .slightlyUnpleasant:
            LocalizedStringResource("pleasantness.slightlyUnpleasant", defaultValue: "Slightly unpleasant")
        case .neutral: LocalizedStringResource("pleasantness.neutral", defaultValue: "Neutral")
        case .slightlyPleasant:
            LocalizedStringResource("pleasantness.slightlyPleasant", defaultValue: "Slightly pleasant")
        case .pleasant: LocalizedStringResource("pleasantness.pleasant", defaultValue: "Pleasant")
        case .veryPleasant: LocalizedStringResource("pleasantness.veryPleasant", defaultValue: "Very pleasant")
        }
    }
}
