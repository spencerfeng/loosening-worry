import Foundation
import Testing

/// Holds the committed catalog against the strings the latest build extracted from source.
/// See "String catalog" in Agents.md.
struct LocalizationCatalogTests {
    @Test
    func `no key the source uses is marked stale`() throws {
        let stale = try StringCatalog.onDisk().keysWronglyMarkedStale(extracted: ExtractedStrings.fromBuild())
        #expect(stale.isEmpty, "Marked stale but still used in source: \(stale.sorted())")
    }

    /// Run the `xcstringstool sync` steps in Agents.md to add missing keys.
    @Test
    func `every key the source uses is in the catalog`() throws {
        let missing = try StringCatalog.onDisk().keysMissing(extracted: ExtractedStrings.fromBuild())
        #expect(missing.isEmpty, "Used in source but missing from the catalog: \(missing.sorted())")
    }

    @Test
    func `the catalog has no trailing newline`() throws {
        #expect(try !StringCatalog.onDisk().endsWithNewline)
    }

    /// Without this setting the compiler stops writing `.stringsdata`. A clean build then has no keys
    /// and the checks above fail, but an incremental build keeps the old files and they would pass.
    @Test
    func `the app target extracts localizable strings`() throws {
        let spec = try String(contentsOf: RepositoryRoot.url.appending(path: "project.yml"), encoding: .utf8)
        let settings = spec.split(separator: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }
            .compactMap { $0.firstMatch(of: /SWIFT_EMIT_LOC_STRINGS:\s*(\S+)/)?.1 }
        #expect(settings == ["YES"], "project.yml must set SWIFT_EMIT_LOC_STRINGS: YES once, on the app target.")
    }
}
