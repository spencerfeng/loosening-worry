import SwiftUI

/// Lays views out left to right, wrapping onto a new row when the next one would not fit.
struct FlowLayout: Layout {
    /// Where each row sits across the width.
    enum Alignment {
        case leading, center
    }

    var spacing: CGFloat = 8
    var alignment: Alignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let frames = frames(for: subviews, in: proposal.width ?? .infinity)
        let width = frames.map(\.maxX).max() ?? 0
        let height = frames.map(\.maxY).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let frames = frames(for: subviews, in: bounds.width)
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size),
            )
        }
    }

    private func frames(for subviews: Subviews, in width: CGFloat) -> [CGRect] {
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)) }
        return Self.frames(for: sizes, in: width, spacing: spacing, alignment: alignment)
    }

    /// Where each item goes: rows fill left to right, and a row ends when the next item wouldn't fit.
    static func frames(for sizes: [CGSize], in width: CGFloat, spacing: CGFloat, alignment: Alignment) -> [CGRect] {
        var rows: [[CGRect]] = [[]]
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        for size in sizes {
            if origin.x > 0, origin.x + size.width > width {
                origin = CGPoint(x: 0, y: origin.y + rowHeight + spacing)
                rowHeight = 0
                rows.append([])
            }
            rows[rows.count - 1].append(CGRect(
                origin: origin,
                size: CGSize(width: min(size.width, width), height: size.height),
            ))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return rows.flatMap { row in
            // An unbounded width has no middle, so a row stays where it is.
            guard alignment == .center, width.isFinite, let last = row.last else { return row }
            let inset = (width - last.maxX) / 2
            return row.map { $0.offsetBy(dx: inset, dy: 0) }
        }
    }
}
