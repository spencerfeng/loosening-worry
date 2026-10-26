@testable import LooseningWorry
import Testing

@MainActor
struct HelpViewModelTests {
    @Test
    func `help opens on the device's country`() {
        let model = HelpViewModel(regionCode: "AU")

        #expect(model.region == .australia)
        #expect(model.support == HelpRegion.australia.support)
    }

    /// Someone traveling, or with their phone set to another region, can switch in one tap.
    @Test
    func `choosing another country shows its lines`() {
        let model = HelpViewModel(regionCode: "AU")

        model.select(.unitedKingdom)

        #expect(model.region == .unitedKingdom)
        #expect(model.support == HelpRegion.unitedKingdom.support)
    }
}
