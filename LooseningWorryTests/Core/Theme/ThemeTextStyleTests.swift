@testable import LooseningWorry
import Testing

/// Pins the type scale to ADR 0002.
struct ThemeTextStyleTests {
    static let scale: [Theme.TextStyle: Theme.TextMetrics] = [
        .largeTitle: .init(face: .extraBold, size: 48, scalesWith: .largeTitle),
        .title: .init(face: .extraBold, size: 28, scalesWith: .title),
        .title2: .init(face: .extraBold, size: 24, scalesWith: .title2),
        .title3: .init(face: .bold, size: 20, scalesWith: .title3),
        .headline: .init(face: .bold, size: 17, scalesWith: .headline),
        .body: .init(face: .regular, size: 16, scalesWith: .body),
        .callout: .init(face: .bold, size: 15, scalesWith: .callout),
        .subheadline: .init(face: .bold, size: 14, scalesWith: .subheadline),
        .footnote: .init(face: .semiBold, size: 13, scalesWith: .footnote),
        .caption: .init(face: .regular, size: 13, scalesWith: .caption),
        .caption2: .init(face: .semiBold, size: 11, scalesWith: .caption2),
    ]

    @Test
    func `every style is pinned`() {
        let unpinned = Theme.TextStyle.allCases.filter { Self.scale[$0] == nil }
        #expect(unpinned.isEmpty, "Add these styles to the scale table: \(unpinned)")
    }

    @Test(arguments: Array(scale.keys))
    func `style matches type scale`(style: Theme.TextStyle) throws {
        let expected = try #require(Self.scale[style])
        #expect(style.metrics == expected)
    }
}
