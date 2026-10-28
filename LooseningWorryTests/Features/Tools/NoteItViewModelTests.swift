import Foundation
@testable import LooseningWorry
import Testing

@MainActor
final class NoteItViewModelTests {
    private let start = Date(timeIntervalSince1970: 1_793_000_000)
    /// Each test gets its own defaults, so nothing leaks between tests or into the app.
    private let suiteName = "NoteItViewModelTests.\(UUID().uuidString)"
    private let run: ToolRunViewModel

    init() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        run = ToolRunViewModel(
            tool: .noteIt,
            now: start,
            picker: PromptPicker(defaults: defaults, prompts: .empty),
            lengths: ToolLengths(defaults: defaults),
        )
    }

    isolated deinit {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    private let worrying = NoteWords.groups[0].words[0]
    private let tight = NoteWords.groups[1].words[0]

    @Test
    func `noting a word counts it`() {
        let model = NoteItViewModel(run: run, now: start)

        model.note(worrying, now: start)
        model.note(worrying, now: start.addingTimeInterval(3))
        model.note(tight, now: start.addingTimeInterval(5))

        #expect(model.count(of: worrying) == 2)
        #expect(model.count(of: tight) == 1)
        #expect(model.count(of: NoteWords.catchAll) == 0)
    }

    /// Note it has no Play: the first word noted starts the time.
    @Test
    func `the first word noted starts the timer`() {
        let model = NoteItViewModel(run: run, now: start)
        #expect(run.hasStarted == false)

        model.note(worrying, now: start.addingTimeInterval(4))
        run.tick(now: start.addingTimeInterval(10))

        #expect(run.hasStarted)
        #expect(run.elapsed == .seconds(6))
    }

    /// After leaving the app, the next word noted carries on the time.
    @Test
    func `a word noted after a pause carries on the timer`() {
        let model = NoteItViewModel(run: run, now: start)
        model.note(worrying, now: start)
        run.leaveApp(now: start.addingTimeInterval(10))

        model.note(tight, now: start.addingTimeInterval(60))
        run.tick(now: start.addingTimeInterval(65))

        #expect(run.isPaused == false)
        #expect(run.elapsed == .seconds(15))
    }

    @Test
    func `nothing is noted once the run is over`() {
        let model = NoteItViewModel(run: run, now: start)
        model.note(worrying, now: start)
        run.end(now: start.addingTimeInterval(20))

        model.note(worrying, now: start.addingTimeInterval(25))

        #expect(model.count(of: worrying) == 1)
    }

    @Test
    func `the tally starts empty`() {
        #expect(NoteItViewModel(run: run, now: start).tally.isEmpty)
    }

    /// The tally shows what's come up most; a tie goes to the word noted last, which is freshest in mind.
    @Test
    func `the tally shows the top three, ties going to the word noted last`() {
        let model = NoteItViewModel(run: run, now: start)
        let words = NoteWords.all
        let (worrying, tight, heavy, hearing) = (words[0], words[4], words[6], words[8])
        for (offset, word) in [worrying, tight, worrying, heavy, hearing, tight, hearing].enumerated() {
            model.note(word, now: start.addingTimeInterval(Double(offset)))
        }

        #expect(model.tally.map(\.word) == [hearing, tight, worrying])
        #expect(model.tally.map(\.count) == [2, 2, 2])
    }

    /// Note it carries on past 1:30, so the screen says the target is reached without cutting anyone off.
    @Test
    func `the run marks when it's past its 1:30 target, and carries on`() {
        let model = NoteItViewModel(run: run, now: start)
        model.note(worrying, now: start)

        run.tick(now: start.addingTimeInterval(89))
        #expect(run.isPastLength == false)

        run.tick(now: start.addingTimeInterval(91))
        #expect(run.isPastLength)
        #expect(run.stage == .running)
    }

    /// The circle asks again only after a quiet spell, so it means "anything here now?" rather than moving on its own.
    @Test
    func `the circle next swells after 10 quiet seconds, then every 10 after`() {
        let model = NoteItViewModel(run: run, now: start)

        #expect(model.nextNudge(after: start.addingTimeInterval(3)) == start.addingTimeInterval(10))
        #expect(model.nextNudge(after: start.addingTimeInterval(10)) == start.addingTimeInterval(20))
        #expect(model.nextNudge(after: start.addingTimeInterval(14)) == start.addingTimeInterval(20))
    }

    @Test
    func `noting a word starts the quiet spell again`() {
        let model = NoteItViewModel(run: run, now: start)

        model.note(worrying, now: start.addingTimeInterval(8))

        #expect(model.nextNudge(after: start.addingTimeInterval(9)) == start.addingTimeInterval(18))
    }

    /// The view floats a bubble and taps the phone for each word counted, so a word refused counts for nothing.
    @Test
    func `the notes so far count only the words noted`() {
        let model = NoteItViewModel(run: run, now: start)
        model.note(worrying, now: start)
        model.note(tight, now: start.addingTimeInterval(2))
        run.end(now: start.addingTimeInterval(5))

        model.note(tight, now: start.addingTimeInterval(6))

        #expect(model.notesSoFar == 2)
    }
}
