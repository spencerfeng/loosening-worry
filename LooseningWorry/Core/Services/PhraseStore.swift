import Foundation
import SwiftData

/// Keeps and lets go of the person's kind phrases; Be kind works through this, so tests can stand in a store that
/// fails.
@MainActor
protocol PhraseKeeping {
    func keep(_ text: String, now: Date) throws
    func remove(_ text: String) throws
    /// The words kept, newest first, each once.
    func phraseTexts() throws -> [String]
}

/// Keeps and lets go of the person's kind phrases. Each change is saved straight away.
@MainActor
struct PhraseStore: PhraseKeeping {
    let context: ModelContext

    /// Keeps `text`, less the spaces around it. A blank isn't kept, and words already kept aren't kept twice.
    func keep(_ text: String, now: Date) throws {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, try !isKept(text) else { return }
        let phrase = KeptPhrase(text: text, keptAt: now)
        context.insert(phrase)
        do {
            try context.save()
        } catch {
            context.delete(phrase)
            throw error
        }
    }

    /// Lets go of every kept copy of `text`.
    func remove(_ text: String) throws {
        for phrase in try kept(text) {
            context.delete(phrase)
        }
        try context.save()
    }

    /// Two devices can each keep the same words before they sync, so each is listed once, where it was kept last.
    func phraseTexts() throws -> [String] {
        var seen: Set<String> = []
        return try phrases().map(\.text).filter { seen.insert($0).inserted }
    }

    func isKept(_ text: String) throws -> Bool {
        try !kept(text).isEmpty
    }

    /// Newest first.
    func phrases() throws -> [KeptPhrase] {
        try context.fetch(FetchDescriptor<KeptPhrase>(sortBy: [SortDescriptor(\.keptAt, order: .reverse)]))
    }

    private func kept(_ text: String) throws -> [KeptPhrase] {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return try context.fetch(FetchDescriptor<KeptPhrase>(predicate: #Predicate { $0.text == text }))
    }
}
