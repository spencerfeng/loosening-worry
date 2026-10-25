import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
struct LoopStoreTests {
    /// The logger closes once Save succeeds, so the loop must be in the store by then.
    @Test
    func `an added loop is saved straight away`() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let loop = Loop(
            trigger: OptionChoice(.news, label: "News"),
            behavior: OptionChoice(.scrolled, label: "Scrolled"),
            result: OptionChoice(.moreWorry, label: "More worry"),
        )

        try LoopStore(context: ModelContext(container)).add(loop)

        let loops = try ModelContext(container).fetch(FetchDescriptor<Loop>())
        #expect(loops.map(\.triggerID) == ["trigger.news"])
    }
}
