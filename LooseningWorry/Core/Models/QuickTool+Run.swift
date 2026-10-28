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

    /// The lengths a person can choose between, first the one a run starts at: Breathe can run longer; the others
    /// have the one length, and a paged tool none.
    var lengthOptions: [Duration] {
        switch self {
        case .breathe: [.seconds(60), .seconds(180), .seconds(300)]
        case .curious, .noteIt: [.seconds(90)]
        case .beKind: []
        }
    }

    /// How long a run is meant to last unless the person chooses otherwise; a paged tool has no length.
    var length: Duration? {
        lengthOptions.first
    }
}

/// A tool opens full screen by itself, so it's the item a cover presents.
extension QuickTool: Identifiable {
    var id: Self {
        self
    }
}
