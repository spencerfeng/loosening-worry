import Foundation

/// How each tool is named and drawn, wherever it appears: Home's grid and Nice catch's suggestion.
extension QuickTool {
    var name: LocalizedStringResource {
        switch self {
        case .curious: LocalizedStringResource("tool.curious.name", defaultValue: "Get curious")
        case .breathe: LocalizedStringResource("tool.breathe.name", defaultValue: "Breathe")
        case .noteIt: LocalizedStringResource("tool.noteIt.name", defaultValue: "Note it")
        case .beKind: LocalizedStringResource("tool.beKind.name", defaultValue: "Be kind")
        }
    }

    /// The SF Symbol in the tool's icon tile.
    var symbol: String {
        switch self {
        case .curious: "magnifyingglass"
        case .breathe: "water.waves"
        case .noteIt: "text.alignleft"
        case .beKind: "heart"
        }
    }

    /// The icon's color; the tile behind it uses `tint`. Each tool keeps one hue (ADR 0001).
    var ink: Theme.ColorRole {
        switch self {
        case .curious: .accentText
        case .breathe: .greenStrong
        case .noteIt: .amberStrong
        case .beKind: .redStrong
        }
    }

    var tint: Theme.ColorRole {
        switch self {
        case .curious: .accentTint
        case .breathe: .greenTint
        case .noteIt: .amberTint
        case .beKind: .redTint
        }
    }
}
