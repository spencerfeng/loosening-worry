import SwiftData

/// Builds the app's SwiftData store, synced through the person's private iCloud database.
enum AppModelContainer {
    static let schema = Schema([LoopOption.self, Loop.self, ToolSession.self, LessonProgress.self])

    /// Must match the container granted in `project.yml`.
    static let iCloudContainer = "iCloud.com.spencerfeng.looseningworry"

    /// `inMemory` gives tests and previews a throwaway store that never syncs.
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: configuration(inMemory: inMemory))
    }

    static func configuration(inMemory: Bool) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .private(iCloudContainer),
        )
    }
}
