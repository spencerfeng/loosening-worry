import Foundation
@testable import LooseningWorry
import Testing

struct AppModelContainerTests {
    @Test
    func `the app's store syncs to the private iCloud container`() {
        let configuration = AppModelContainer.configuration(inMemory: false)

        #expect(configuration.cloudKitContainerIdentifier == AppModelContainer.iCloudContainer)
        #expect(AppModelContainer.iCloudContainer == "iCloud.com.spencerfeng.looseningworry")
    }

    @Test
    func `an in-memory store never syncs`() {
        let configuration = AppModelContainer.configuration(inMemory: true)

        #expect(configuration.isStoredInMemoryOnly)
        #expect(configuration.cloudKitContainerIdentifier == nil)
    }

    /// XcodeGen writes this file from `project.yml`, so it holds exactly what the app is signed with.
    @Test
    func `the app is entitled to the iCloud container the store syncs to`() throws {
        let data = try Data(contentsOf: RepositoryRoot.url
            .appending(path: "LooseningWorry/LooseningWorry.entitlements"))
        let entitlements = try #require(
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        #expect(entitlements["com.apple.developer.icloud-container-identifiers"] as? [String] ==
            [AppModelContainer.iCloudContainer])
        #expect(entitlements["com.apple.developer.icloud-services"] as? [String] == ["CloudKit"])
        #expect(entitlements["aps-environment"] != nil)
    }

    /// The tests run inside the app, so the main bundle is the app itself.
    @Test
    func `the app wakes in the background for CloudKit pushes`() {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]

        #expect(modes?.contains("remote-notification") == true)
    }
}
