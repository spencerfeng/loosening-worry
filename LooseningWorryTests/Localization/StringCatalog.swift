import Foundation

/// The parts of `Localizable.xcstrings` the localization checks read.
///
/// `extractionState` is written by Xcode, not by hand, so nobody reads it in a diff. When extraction
/// breaks, live keys get marked stale or never get added, and the only symptom is copy quietly missing
/// from *Export Localizations*. See "String catalog" in Agents.md.
struct StringCatalog {
    /// Xcode's verdict on an entry. Only `stale` matters here; other values pass through untouched.
    enum ExtractionState: Equatable, Decodable {
        case stale
        case other(String)

        init(from decoder: any Decoder) throws {
            let value = try decoder.singleValueContainer().decode(String.self)
            self = value == "stale" ? .stale : .other(value)
        }
    }

    private struct Entry: Decodable {
        let extractionState: ExtractionState?
    }

    private struct Contents: Decodable {
        let strings: [String: Entry]
    }

    private let strings: [String: Entry]
    /// Xcode writes the catalog without one, so a stored newline makes every IDE build rewrite the file.
    let endsWithNewline: Bool

    init(data: Data) throws {
        strings = try JSONDecoder().decode(Contents.self, from: data).strings
        endsWithNewline = data.last == UInt8(ascii: "\n")
    }

    /// The committed catalog.
    static func onDisk() throws -> StringCatalog {
        try StringCatalog(data: Data(contentsOf: RepositoryRoot.url.appending(
            path: "LooseningWorry/Resources/Localizable.xcstrings"
        )))
    }

    var keys: Set<String> {
        Set(strings.keys)
    }

    /// Keys Xcode has marked stale. Hand-authored entries, such as plurals, carry no extraction state.
    var staleKeys: Set<String> {
        Set(strings.filter { $0.value.extractionState == .stale }.keys)
    }

    /// Keys the source still uses but the catalog marks stale. *Export Localizations* skips stale keys,
    /// so these never reach a translator.
    func keysWronglyMarkedStale(extracted: Set<String>) -> Set<String> {
        extracted.intersection(staleKeys)
    }

    /// Keys the source uses that the catalog doesn't have.
    func keysMissing(extracted: Set<String>) -> Set<String> {
        extracted.subtracting(keys)
    }
}
