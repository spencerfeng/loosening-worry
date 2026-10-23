import Foundation

/// The localizable keys the compiler extracted from source, read from its `.stringsdata` output.
enum ExtractedStrings {
    enum ReadError: Error, CustomStringConvertible {
        case directoryNotSet
        case noLocalizableKeys(URL)

        var description: String {
            switch self {
            case .directoryNotSet:
                "LOCALIZATION_STRINGSDATA_DIR is not set. The test scheme in project.yml points it at the app "
                    + "target's build intermediates."
            case let .noLocalizableKeys(directory):
                "The build extracted no Localizable keys under \(directory.path()). Is SWIFT_EMIT_LOC_STRINGS: "
                    + "YES still set on the app target in project.yml?"
            }
        }
    }

    /// Keys from the latest build of the app target, whose location the test scheme passes in.
    static func fromBuild() throws -> Set<String> {
        let path = ProcessInfo.processInfo.environment["LOCALIZATION_STRINGSDATA_DIR"] ?? ""
        guard !path.isEmpty else {
            throw ReadError.directoryNotSet
        }
        return try keys(inDirectory: URL(filePath: path, directoryHint: .isDirectory))
    }

    /// Every `Localizable` key in the `.stringsdata` files under `directory`.
    ///
    /// Files whose source no longer exists are left over from earlier builds and are skipped. Throws
    /// rather than return an empty set, which would let every check pass without checking anything:
    /// with extraction off, the build still writes `.stringsdata` for App Intents metadata, just no keys.
    static func keys(inDirectory directory: URL) throws -> Set<String> {
        let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "stringsdata" } ?? []
        let keys = try files.reduce(into: Set<String>()) { keys, file in
            let stringsdata = try Stringsdata(data: Data(contentsOf: file))
            if FileManager.default.fileExists(atPath: stringsdata.source) {
                keys.formUnion(stringsdata.localizableKeys)
            }
        }
        guard !keys.isEmpty else {
            throw ReadError.noLocalizableKeys(directory)
        }
        return keys
    }

    /// The `Localizable` keys in one `.stringsdata` file.
    static func keys(inStringsdata data: Data) throws -> Set<String> {
        try Stringsdata(data: data).localizableKeys
    }
}

/// The slice of a `.stringsdata` file these tests read.
private struct Stringsdata: Decodable {
    struct Entry: Decodable {
        let key: String
    }

    let source: String
    let tables: [String: [Entry]]

    init(data: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: data)
    }

    var localizableKeys: Set<String> {
        Set(tables["Localizable", default: []].map(\.key))
    }
}
