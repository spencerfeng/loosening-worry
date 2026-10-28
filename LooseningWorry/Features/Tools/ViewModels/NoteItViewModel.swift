import Foundation
import Observation

/// Note it: each word tapped is counted. With no Play, the first word noted starts the time, and a word noted after a
/// pause carries it on. The "What's here?" circle asks again after each quiet spell.
@Observable @MainActor
final class NoteItViewModel {
    struct Tally: Equatable {
        let word: NoteWord
        let count: Int
    }

    let run: ToolRunViewModel
    /// How many words have been noted, which the view follows to float a bubble and tap the phone for each.
    private(set) var notesSoFar = 0

    /// How many times a word's been noted, and when it was last (as a running number), which breaks ties in the tally.
    private struct Record {
        var times = 0
        var lastNoted = 0
    }

    private var records: [NoteWordID: Record] = [:]
    /// When the person last noted something, or opened the tool: the start of the current quiet spell.
    private var quietSince: Date

    init(run: ToolRunViewModel, now: Date) {
        self.run = run
        quietSince = now
    }

    func note(_ word: NoteWord, now: Date) {
        guard run.stage == .running else { return }
        notesSoFar += 1
        records[word.id, default: Record()].times += 1
        records[word.id, default: Record()].lastNoted = notesSoFar
        quietSince = now
        run.play(now: now)
    }

    func count(of word: NoteWord) -> Int {
        records[word.id]?.times ?? 0
    }

    /// When the "What's here?" circle next swells, asking again: after every 10 seconds with nothing noted.
    func nextNudge(after now: Date) -> Date {
        let spells = (now.timeIntervalSince(quietSince) / Self.quietSpell).rounded(.down) + 1
        return quietSince.addingTimeInterval(max(spells, 1) * Self.quietSpell)
    }

    private static let quietSpell: TimeInterval = 10

    /// "So far: hearing ×2 · tight ×2 · worrying ×2": the three words noted most, a tie going to the one noted last.
    var tally: [Tally] {
        records
            .filter { $0.value.times > 0 }
            .sorted { ($0.value.times, $0.value.lastNoted) > ($1.value.times, $1.value.lastNoted) }
            .prefix(3)
            .map { Tally(word: NoteWord(id: $0.key), count: $0.value.times) }
    }
}
