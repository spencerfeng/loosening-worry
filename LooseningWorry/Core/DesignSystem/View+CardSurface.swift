import SwiftUI

extension View {
    /// The app's card: the surface color under a rounded outline. Each card keeps its own corner radius.
    func cardSurface(
        cornerRadius: CGFloat,
        outline: Theme.ColorRole = .borderSubtle,
        lineWidth: CGFloat = 1,
    ) -> some View {
        background(.theme(.surface), in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(.theme(outline), lineWidth: lineWidth)
            }
    }
}
