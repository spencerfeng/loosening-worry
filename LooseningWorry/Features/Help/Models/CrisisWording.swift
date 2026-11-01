import Foundation

/// Spots words that suggest the person may be in crisis, so the app can point them to Help. Plain rules, never the
/// model: they behave the same every time and can be read and reviewed. They only add a way to Help, so a phrase that
/// is sometimes meant lightly still belongs here.
///
/// English only, like the starter options. The phrases need a clinician's review before launch.
enum CrisisWording {
    static func appears(in text: String) -> Bool {
        let words = normalized(text)
        return phrases.contains { words.contains(" \($0) ") }
    }

    /// Lowercase words with apostrophes dropped ("can't" reads as "cant"), everything else that isn't a letter or
    /// digit read as a space, and a space at each end so phrases match whole words.
    private static func normalized(_ text: String) -> String {
        let letters = text.lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "")
            .map { $0.isLetter || $0.isNumber ? $0 : " " }
        let words = String(letters).split(separator: " ")
        return " " + words.joined(separator: " ") + " "
    }

    private static let phrases = [
        "kill myself", "killing myself", "end my life", "ending my life", "take my own life", "end it all",
        "suicide", "suicidal", "want to die", "wanna die", "dont want to be here", "dont want to live",
        "better off without me", "no reason to live", "not worth living", "cant go on",
        "hurt myself", "hurting myself", "harm myself", "harming myself", "self harm", "cut myself", "cutting myself",
    ]
}
