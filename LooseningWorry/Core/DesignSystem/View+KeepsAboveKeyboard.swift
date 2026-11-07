import SwiftUI

extension View {
    /// Keeps the view with `id` in this scroll view above the keyboard while `isShowing`: when it appears, and again
    /// once the keyboard has shrunk the visible area. Used for a step's "+ Add your own" field and its Add button.
    func keepsAboveKeyboard(
        _ id: some Hashable,
        isShowing: Bool,
        in proxy: ScrollViewProxy,
        animation: Animation?,
    ) -> some View {
        let reveal = {
            guard isShowing else { return }
            withAnimation(animation) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
        return onChange(of: isShowing) { reveal() }
            .onGeometryChange(for: CGFloat.self) { $0.size.height - $0.safeAreaInsets.bottom } action: { _ in
                reveal()
            }
    }
}
