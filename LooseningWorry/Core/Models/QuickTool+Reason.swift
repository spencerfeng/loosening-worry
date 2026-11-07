import Foundation

/// What each tool does for a hard feeling, in a line under its name on a tool card: the check-in's tools and the
/// logger's "Nothing yet". Drafts for the reviewer.
extension QuickTool {
    var reason: LocalizedStringResource {
        switch self {
        case .curious:
            LocalizedStringResource(
                "tool.reason.curious",
                defaultValue: "Look at the worry instead of being pulled along by it",
            )
        case .breathe: LocalizedStringResource(
                "tool.reason.breathe",
                defaultValue: "Rest your attention on your breath",
            )
        case .noteIt:
            LocalizedStringResource("tool.reason.noteIt", defaultValue: "Name what's here, one word at a time")
        case .beKind:
            LocalizedStringResource("tool.reason.beKind", defaultValue: "Meet the harsh inner voice with warmth")
        }
    }
}
