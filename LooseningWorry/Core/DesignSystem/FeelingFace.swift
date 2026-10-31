import SwiftUI

/// The design's faces, for the finish screen's feelings and onboarding's loop: a circle and two eyes, with a smile,
/// a flat mouth or a frown.
struct FeelingFace: Shape {
    let feeling: Feeling

    func path(in rect: CGRect) -> Path {
        // Drawn on the design's 40 by 40 grid, then scaled to fit.
        let scale = min(rect.width, rect.height) / 40
        var path = Path()
        path.addEllipse(in: CGRect(x: 3, y: 3, width: 34, height: 34))
        for eyeX in [14.0, 26.0] {
            path.addEllipse(in: CGRect(x: eyeX - 0.4, y: 15.6, width: 0.8, height: 0.8))
        }
        switch feeling {
        case .lighter:
            path.move(to: CGPoint(x: 13, y: 24))
            path.addCurve(to: CGPoint(x: 27, y: 24), control1: CGPoint(x: 15, y: 27), control2: CGPoint(x: 25, y: 27))
        case .same:
            path.move(to: CGPoint(x: 13.5, y: 26))
            path.addLine(to: CGPoint(x: 26.5, y: 26))
        case .heavier:
            path.move(to: CGPoint(x: 13, y: 28))
            path.addCurve(to: CGPoint(x: 27, y: 28), control1: CGPoint(x: 15, y: 25), control2: CGPoint(x: 25, y: 25))
        }
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}
