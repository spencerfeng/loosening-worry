import Foundation
import Observation

/// Help: crisis lines for the person's country, which they can change for this visit.
@Observable @MainActor
final class HelpViewModel {
    private(set) var region: HelpRegion

    /// The emergency number and crisis lines for `region`.
    var support: CrisisSupport {
        region.support
    }

    /// - Parameter regionCode: The device's region, such as "AU". The choice isn't saved, so Help opens on the
    ///   device's country every time.
    init(regionCode: String? = Locale.current.region?.identifier) {
        region = HelpRegion(regionCode: regionCode)
    }

    func select(_ region: HelpRegion) {
        self.region = region
    }
}
