import SwiftData
import SwiftUI

@main
struct LooseningWorryApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    /// Before launch the store can only fail to open through a setup mistake, so crash loudly.
    /// Once people have data, replace this with a "couldn't open your data" screen (M6, with SchemaV1).
    private let modelContainer: ModelContainer = {
        do {
            return try AppModelContainer.make()
        } catch {
            fatalError("Could not open the data store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView(model: appDelegate.rootModel)
        }
        .modelContainer(modelContainer)
    }
}
