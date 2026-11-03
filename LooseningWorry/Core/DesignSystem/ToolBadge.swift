import SwiftUI

/// A tool's symbol in its own color on its tint (ADR 0001), as on Home's Quick tools, the tool card and the
/// check-in's other tools. Decoration beside the tool's name, so VoiceOver skips it.
struct ToolBadge: View {
    enum Size {
        /// Over or beside just the name, as on Home's Quick tools and the check-in's tiles.
        case tile
        /// Beside a name and a line about the tool, as on the tool card.
        case card

        fileprivate var side: CGFloat {
            switch self {
            case .tile: 36
            case .card: 40
            }
        }

        fileprivate var symbolSize: CGFloat {
            switch self {
            case .tile: 18
            case .card: 20
            }
        }
    }

    let tool: QuickTool
    var size = Size.tile

    var body: some View {
        Image(systemName: tool.symbol)
            .font(.system(size: size.symbolSize, weight: .semibold))
            .foregroundStyle(.theme(tool.ink))
            .frame(width: size.side, height: size.side)
            .background(.theme(tool.tint), in: .rect(cornerRadius: 12))
            .accessibilityHidden(true)
    }
}
