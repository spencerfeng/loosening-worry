import CoreGraphics
@testable import LooseningWorry
import Testing

struct FlowLayoutTests {
    private let sizes = [CGSize(width: 40, height: 20), CGSize(width: 30, height: 20), CGSize(width: 50, height: 20)]

    @Test
    func `items wrap onto a new row when the next one won't fit`() {
        let frames = FlowLayout.frames(for: sizes, in: 100, spacing: 10, alignment: .leading)

        #expect(frames.map(\.origin) == [CGPoint(x: 0, y: 0), CGPoint(x: 50, y: 0), CGPoint(x: 0, y: 30)])
    }

    /// Nice catch centers its chips, so a row that wraps sits under the middle of the one above.
    @Test
    func `centered rows sit in the middle of the width`() {
        let frames = FlowLayout.frames(for: sizes, in: 100, spacing: 10, alignment: .center)

        // Row one is 80 wide, so it starts 10 in; row two is 50 wide, so it starts 25 in.
        #expect(frames.map(\.origin) == [CGPoint(x: 10, y: 0), CGPoint(x: 60, y: 0), CGPoint(x: 25, y: 30)])
    }
}
