import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
struct CheckInStoreTests {
    let container: ModelContainer

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
    }

    /// The finish screen shows once Done succeeds, so the check-in must be in the store by then.
    @Test
    func `an added check-in is saved straight away`() throws {
        let answer = CheckInAnswer(pleasantness: .unpleasant, feelings: [.worried])
        try CheckInStore(context: ModelContext(container)).add(CheckIn(answer))

        let checkIns = try ModelContext(container).fetch(FetchDescriptor<CheckIn>())
        #expect(checkIns.map(\.feelings) == [[.worried]])
    }
}
