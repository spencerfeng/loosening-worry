#!/usr/bin/env swift

import Foundation

// Puts the string catalog back into the collation Xcode writes, so the file stops flipping between
// two orderings. Xcode and `xcstringstool` disagree: the tool sorts keys by byte value, Xcode sorts
// them case-insensitively with punctuation-only keys first, the order Finder uses. Whichever wrote
// last leaves the file dirty against the other, and a permanently dirty file is one people discard
// without reading. See "String catalog" in Agents.md.
//
// Entries are moved as raw text rather than re-serialised, so every byte inside an entry survives —
// escaping, key order within an entry, and the blank line Xcode leaves inside an empty one. Keys are
// sorted by their decoded text, so a key written with escapes sorts where its characters belong.

let catalogPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "LooseningWorry/Resources/Localizable.xcstrings"

// Pinned rather than the current locale: the ordering a contributor commits must not depend on
// their system settings. This option set is what `localizedStandardCompare` applies.
private let collationLocale = Locale(identifier: "en_US")
private let collationOptions: String.CompareOptions = [
    .caseInsensitive, .numeric, .widthInsensitive, .forcedOrdering,
]

private struct Entry {
    let key: String
    /// The entry exactly as written, from its opening line to its closing brace, comma excluded.
    let text: String
}

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("normalize-string-catalog: \(message)\n".utf8))
    exit(1)
}

private let url = URL(fileURLWithPath: catalogPath)
guard let original = try? String(contentsOf: url, encoding: .utf8) else {
    fail("cannot read \(catalogPath)")
}

private let lines = original.components(separatedBy: "\n")
guard let stringsIndex = lines.firstIndex(of: "  \"strings\" : {") else {
    fail("no top-level \"strings\" object in \(catalogPath) — has the format changed?")
}

/// Brace depth of a line, ignoring braces that sit inside a JSON string.
private func braceDelta(_ line: String) -> Int {
    var delta = 0
    var isInString = false
    var isEscaped = false
    for character in line {
        if isEscaped {
            isEscaped = false
            continue
        }
        switch character {
        case "\\" where isInString: isEscaped = true
        case "\"": isInString.toggle()
        case "{" where !isInString: delta += 1
        case "}" where !isInString: delta -= 1
        default: break
        }
    }
    return delta
}

/// The decoded key of an entry's opening line, `    "<key>" : {`, or nil if the line isn't one.
private func entryKey(_ opening: String) -> String? {
    let prefix = "    "
    guard opening.hasPrefix(prefix + "\"") else { return nil }
    var literal = ""
    var isEscaped = false
    var rest = opening.dropFirst(prefix.count)
    while let character = rest.first {
        literal.append(character)
        rest = rest.dropFirst()
        if isEscaped {
            isEscaped = false
        } else if character == "\\" {
            isEscaped = true
        } else if character == "\"", literal.count > 1 {
            break
        }
    }
    guard rest.hasPrefix(" : {") else { return nil }
    let decoded = try? JSONSerialization.jsonObject(with: Data(literal.utf8), options: .fragmentsAllowed)
    return decoded as? String
}

private var entries: [Entry] = []
private var current: [String] = []
private var depth = 0
private var index = stringsIndex + 1

while index < lines.count {
    let line = lines[index]
    if depth == 0, line == "  }," || line == "  }" {
        break
    }
    // Xcode writes an empty "strings" object as an opening brace, a blank line and a closing brace.
    if depth == 0, current.isEmpty, line.isEmpty {
        index += 1
        continue
    }
    current.append(line)
    depth += braceDelta(line)
    if depth == 0 {
        let text = current.joined(separator: "\n")
        guard let opening = current.first, let key = entryKey(opening) else {
            fail("unrecognised entry starting: \(current.first ?? "")")
        }
        entries.append(Entry(key: key, text: text.hasSuffix(",") ? String(text.dropLast()) : text))
        current = []
    }
    index += 1
}

guard depth == 0, current.isEmpty, index < lines.count else {
    fail("unbalanced braces in \(catalogPath)")
}

private let header = lines[...stringsIndex].joined(separator: "\n")
private let footer = lines[index...].joined(separator: "\n")

private let sorted = entries.sorted {
    $0.key.compare($1.key, options: collationOptions, range: nil, locale: collationLocale)
        == .orderedAscending
}

/// With no entries there is nothing to reorder; keep whatever sat between the braces as it was.
private let body = entries.isEmpty
    ? lines[(stringsIndex + 1) ..< index].map { $0 + "\n" }.joined()
    : sorted.map(\.text).joined(separator: ",\n") + "\n"

private var normalized = header + "\n" + body + footer
while normalized.hasSuffix("\n") {
    normalized.removeLast()
}

/// The reorder must not change what the file says. Compare the parsed contents, not the text, so a
/// bug in the block scanner above fails the commit instead of writing a mangled catalog.
private func decoded(_ text: String) -> NSDictionary? {
    guard let data = text.data(using: .utf8) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary
}

guard let before = decoded(original), let after = decoded(normalized) else {
    fail("\(catalogPath) is not valid JSON — nothing written")
}

guard before == after else {
    fail("reordering changed the catalog's contents — nothing written")
}

if normalized == original {
    exit(0)
}

do {
    try normalized.write(to: url, atomically: true, encoding: .utf8)
} catch {
    fail("cannot write \(catalogPath): \(error.localizedDescription)")
}

print("normalize-string-catalog: reordered \(entries.count) entries in \(catalogPath)")
