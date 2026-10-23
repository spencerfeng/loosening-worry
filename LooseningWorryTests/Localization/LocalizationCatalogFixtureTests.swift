import Foundation
import Testing

/// Proves each catalog check catches what it guards against, using small hand-written catalogs.
struct LocalizationCatalogFixtureTests {
    private static let catalog = Data("""
    {
      "sourceLanguage" : "en",
      "strings" : {
        "home.title" : {
          "extractionState" : "stale"
        },
        "settings.title" : {

        },
        "worries.count" : {
          "localizations" : {
            "en" : {
              "variations" : {
                "plural" : {
                  "one" : { "stringUnit" : { "state" : "translated", "value" : "%lld worry" } },
                  "other" : { "stringUnit" : { "state" : "translated", "value" : "%lld worries" } }
                }
              }
            }
          }
        }
      },
      "version" : "1.0"
    }
    """.utf8)

    /// What `swiftc -emit-localized-strings` wrote for `String(localized: "worries.count", defaultValue:
    /// "\(count) worries")` and `String(localized: "home.greeting")`: the bare key, as the catalog stores it.
    private static let compilerOutput = Data("""
    {
      "source": "Sample.swift",
      "tables": {
        "Localizable": [
          {
            "comment": "",
            "key": "worries.count",
            "location": { "startingColumn": 27, "startingLine": 5 },
            "value": "%lld worries"
          },
          {
            "comment": "",
            "key": "home.greeting",
            "location": { "startingColumn": 27, "startingLine": 6 }
          }
        ]
      },
      "version": 1
    }
    """.utf8)

    @Test(arguments: [
        (extracted: ["home.title", "settings.title"], reported: ["home.title"]),
        (extracted: ["worries.count"], reported: []), // hand-authored plural, no extraction state
    ] as [(Set<String>, Set<String>)])
    func `stale check reports keys the source still uses`(extracted: Set<String>, reported: Set<String>) throws {
        #expect(try StringCatalog(data: Self.catalog).keysWronglyMarkedStale(extracted: extracted) == reported)
    }

    @Test(arguments: [
        (extracted: ["settings.title", "onboarding.welcome"], reported: ["onboarding.welcome"]),
        (extracted: ["worries.count"], reported: []), // hand-authored plural, no extraction state
    ] as [(Set<String>, Set<String>)])
    func `missing check reports keys the catalog lacks`(extracted: Set<String>, reported: Set<String>) throws {
        #expect(try StringCatalog(data: Self.catalog).keysMissing(extracted: extracted) == reported)
    }

    @Test
    func `a String(localized:) key with a plural default value matches its hand-authored catalog entry`() throws {
        let extracted = try ExtractedStrings.keys(inStringsdata: Self.compilerOutput)
        #expect(extracted == ["worries.count", "home.greeting"])
        #expect(try StringCatalog(data: Self.catalog).keysMissing(extracted: extracted) == ["home.greeting"])
    }

    @Test
    func `only the Localizable table's keys count as extracted`() throws {
        let stringsdata = Self.stringsdata(source: "/tmp/Example.swift", tables: [
            "Localizable": ["home.title"], "InfoPlist": ["CFBundleDisplayName"],
        ])
        #expect(try ExtractedStrings.keys(inStringsdata: stringsdata) == ["home.title"])
    }

    @Test
    func `stringsdata left behind by a deleted source file is ignored`() throws {
        let directory = try Self.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.stringsdata(source: #filePath, tables: ["Localizable": ["live.key"]])
            .write(to: directory.appending(path: "Live.stringsdata"))
        try Self.stringsdata(source: "/nonexistent/Deleted.swift", tables: ["Localizable": ["deleted.key"]])
            .write(to: directory.appending(path: "Deleted.stringsdata"))

        #expect(try ExtractedStrings.keys(inDirectory: directory) == ["live.key"])
    }

    @Test
    func `a build with no Localizable keys fails instead of passing on nothing`() throws {
        let directory = try Self.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.stringsdata(source: #filePath, tables: [:])
            .write(to: directory.appending(path: "ExtractedAppShortcutsMetadata.stringsdata"))

        #expect(throws: ExtractedStrings.ReadError.self) {
            try ExtractedStrings.keys(inDirectory: directory)
        }
    }

    private static func stringsdata(source: String, tables: [String: [String]]) -> Data {
        let json: [String: Any] = [
            "source": source,
            "tables": tables.mapValues { $0.map { ["comment": "", "key": $0] } },
            "version": 1,
        ]
        // A fixed literal dictionary always serialises.
        // swiftlint:disable:next force_try
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
