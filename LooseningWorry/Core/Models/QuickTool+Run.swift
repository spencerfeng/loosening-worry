import Foundation

/// How a tool sets its pace, which decides its timer and what the shell shows.
enum ToolPacing {
    /// Guided against the clock: a bar with the time and Play, and the run ends when the time is up.
    case timed
    /// Paced by the person's own taps: the first one starts the time, shown in the header, and the length is a target
    /// the run carries on past until End.
    case counted
    /// Paced by the person turning pages: no time is shown, and the run ends on Finish or End.
    case paged
}

extension QuickTool {
    var pacing: ToolPacing {
        switch self {
        case .curious, .breathe: .timed
        case .noteIt: .counted
        case .beKind: .paged
        }
    }

    /// How long a run is meant to last; a paged tool has no length.
    var length: Duration? {
        switch self {
        case .breathe: .seconds(60)
        case .curious, .noteIt: .seconds(90)
        case .beKind: nil
        }
    }
}

/// A tool opens full screen by itself, so it's the item a cover presents.
extension QuickTool: Identifiable {
    var id: Self {
        self
    }
}
