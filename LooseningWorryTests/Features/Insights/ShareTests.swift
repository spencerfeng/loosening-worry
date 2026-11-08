@testable import LooseningWorry
import Testing

struct ShareTests {
    /// How much of a bar a share fills; with nothing counted yet there's nothing to fill, rather than a division by
    /// zero.
    @Test(arguments: [(3, 4, 0.75), (2, 2, 1.0), (0, 5, 0.0), (0, 0, 0.0)])
    func `a share fills its count out of its total`(count: Int, total: Int, fraction: Double) {
        #expect(Share(count: count, total: total).fraction == fraction)
    }
}
