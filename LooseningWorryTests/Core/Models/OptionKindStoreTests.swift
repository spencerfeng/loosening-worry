import Foundation
@testable import LooseningWorry
import SQLite3
import SwiftData
import Testing

/// A synced option can carry a kind from a newer version. SwiftData decodes a stored kind as it fetches, and one it
/// can't decode crashes the fetch, so these read a real store holding such a kind.
struct OptionKindStoreTests {
    @Test
    func `an option of a kind from a newer version loads as unrecognized, and the rest keep theirs`() throws {
        let url = URL.temporaryDirectory.appending(path: "options-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let context = try ModelContext(Self.container(at: url))
            context.insert(LoopOption(kind: .behavior, label: "Paced"))
            context.insert(LoopOption(kind: .trigger, label: "Moved house"))
            try context.save()
        }
        // What a newer version syncing a kind of its own would leave in the store.
        try Self.execute("UPDATE ZLOOPOPTION SET ZKIND = 'addedLater' WHERE ZLABEL = 'Moved house'", at: url)

        let options = try ModelContext(Self.container(at: url)).fetch(FetchDescriptor<LoopOption>())

        let kinds = Dictionary(uniqueKeysWithValues: options.map { ($0.label, $0.kind) })
        #expect(kinds == ["Paced": .behavior, "Moved house": .unrecognized])
        #expect(OptionKind.allCases.allSatisfy { kind in
            !OptionList.choices(for: kind, saved: options).contains { $0.label == "Moved house" }
        })
    }

    private static func container(at url: URL) throws -> ModelContainer {
        try ModelContainer(
            for: Schema([LoopOption.self]),
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none),
        )
    }

    private struct SQLiteError: Error {
        let message: String
    }

    private static func execute(_ sql: String, at url: URL) throws {
        var database: OpaquePointer?
        defer { sqlite3_close(database) }
        guard sqlite3_open(url.path, &database) == SQLITE_OK else {
            throw SQLiteError(message: String(cString: sqlite3_errmsg(database)))
        }
        // The store SwiftData wrote can still be open while it winds down, so wait for its lock rather than fail.
        sqlite3_busy_timeout(database, 5000)
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK, sqlite3_changes(database) == 1 else {
            throw SQLiteError(message: String(cString: sqlite3_errmsg(database)))
        }
    }
}
