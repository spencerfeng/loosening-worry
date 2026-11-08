@testable import LooseningWorry
import Testing

/// A logger with all three steps answered.
@MainActor
private func finishedModel() -> LogLoopViewModel {
    let model = LogLoopViewModel()
    model.pick(.news)
    model.pick(.scrolled)
    model.pick(.moreWorry)
    return model
}

// MARK: - Save

@MainActor
struct LogLoopSaveTests {
    @Test
    func `a loop can be saved only once all three steps are answered and none is reopened`() {
        let model = LogLoopViewModel()
        #expect(model.canSave == false)

        model.pick(.news)
        model.pick(.scrolled)
        #expect(model.canSave == false)

        model.pick(.moreWorry)
        #expect(model.canSave)

        model.goTo(.behavior)
        #expect(model.canSave == false)
    }

    @Test
    func `saving stores a loop with each answer's id and text`() throws {
        let model = finishedModel()
        var stored: [Loop] = []

        model.save { stored.append($0) } history: { [$0] }

        let loop = try #require(stored.only)
        #expect(loop.triggerID == "trigger.news")
        #expect(loop.triggerLabel == "News")
        #expect(loop.behaviorID == "behavior.scrolled")
        #expect(loop.behaviorLabel == "Scrolled")
        #expect(loop.resultID == "result.moreWorry")
        #expect(loop.resultLabel == "More worry")
        #expect(loop.anxiety == nil)
        #expect(loop.note == nil)
        #expect(model.isSaved)
    }

    /// The history is read once this loop is stored, so it's among them.
    @Test
    func `saving leads to Nice catch, with the last times this trigger led to this habit`() throws {
        let model = finishedModel()
        let earlier = Loop.sample(
            trigger: OptionChoice(.news, label: "News"),
            behavior: OptionChoice(.scrolled, label: "Scrolled"),
            result: OptionChoice(.littleRelief, label: "A little relief"),
        )
        var stored: [Loop] = [earlier]

        model.save { stored.append($0) } history: { loop in
            #expect(stored.last === loop)
            return stored
        }

        let niceCatch = try #require(model.niceCatch)
        #expect(niceCatch.chips == ["News", "Scrolled", "More worry"])
        #expect(niceCatch.lastTimes?.outcomes == [.relief, .noBetter])
    }

    /// The loop is saved either way; there's just nothing to compare it with.
    @Test
    func `if the history can't be read, Nice catch shows no last times`() throws {
        struct ReadFailed: Error {}
        let model = finishedModel()

        model.save { _ in } history: { _ in throw ReadFailed() }

        #expect(try #require(model.niceCatch).lastTimes == nil)
        #expect(model.isSaved)
    }

    @Test
    func `an unfinished loop isn't saved`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        var stored: [Loop] = []

        model.save { stored.append($0) } history: { [$0] }

        #expect(stored.isEmpty)
        #expect(model.isSaved == false)
    }

    /// A second tap on Save, before the logger closes, must not log the loop twice.
    @Test
    func `saving twice stores the loop once`() {
        let model = finishedModel()
        var stored: [Loop] = []

        model.save { stored.append($0) } history: { [$0] }
        model.save { stored.append($0) } history: { [$0] }

        #expect(stored.count == 1)
        #expect(model.canSave == false)
    }

    @Test
    func `when saving fails, the person is told and can try again`() {
        struct SaveFailed: Error {}
        let model = finishedModel()

        model.save { _ in throw SaveFailed() } history: { [$0] }

        #expect(model.isSaved == false)
        #expect(model.saveFailed)
        #expect(model.canSave)

        var stored: [Loop] = []
        model.save { stored.append($0) } history: { [$0] }

        #expect(stored.count == 1)
        #expect(model.isSaved)
        #expect(model.saveFailed == false)
    }

    /// The message is about the loop as it was; once the person changes an answer it no longer applies.
    @Test
    func `reopening a step clears the message that saving failed`() {
        struct SaveFailed: Error {}
        let model = finishedModel()
        model.save { _ in throw SaveFailed() } history: { [$0] }

        model.goTo(.trigger)

        #expect(model.saveFailed == false)
    }
}

// MARK: - When did you notice

@MainActor
struct LogLoopNoticedTests {
    @Test
    func `when the person noticed is saved with the loop`() throws {
        let model = finishedModel()
        model.notice(.whileHappening)
        var stored: [Loop] = []

        model.save { stored.append($0) } history: { [$0] }

        #expect(try #require(stored.only).noticed == .whileHappening)
    }

    /// The question is optional, so logging never takes longer than the three steps.
    @Test
    func `a loop saved without an answer says nothing about when it was noticed`() throws {
        let model = finishedModel()
        var stored: [Loop] = []

        model.save { stored.append($0) } history: { [$0] }

        #expect(try #require(stored.only).noticed == nil)
    }

    @Test
    func `changing the answer before saving keeps the last one`() throws {
        let model = finishedModel()
        model.notice(.whileHappening)
        model.notice(.afterwards)
        var stored: [Loop] = []

        model.save { stored.append($0) } history: { [$0] }

        #expect(try #require(stored.only).noticed == .afterwards)
    }

    /// The question is optional, so a mistaken tap mustn't leave an answer the person can't take back.
    @Test
    func `tapping the chosen answer again takes it back`() throws {
        let model = finishedModel()
        model.notice(.whileHappening)

        model.notice(.whileHappening)

        #expect(model.noticed == nil)
        var stored: [Loop] = []
        model.save { stored.append($0) } history: { [$0] }
        #expect(try #require(stored.only).noticed == nil)
    }
}

// MARK: - Details

@MainActor
struct LogLoopDetailsTests {
    /// Opening the details must not record a level the person never chose.
    @Test
    func `the anxiety level stays unset until the person sets it`() throws {
        let model = finishedModel()
        model.toggleDetails()
        #expect(model.isShowingDetails)
        #expect(model.anxiety == nil)

        model.setAnxiety(7)
        var stored: [Loop] = []
        model.save { stored.append($0) } history: { [$0] }

        #expect(try #require(stored.only).anxiety == 7)
    }

    @Test(arguments: [(-1, 0), (0, 0), (10, 10), (11, 10)])
    func `the anxiety level stays within 0 to 10`(level: Int, kept: Int) {
        let model = finishedModel()
        model.toggleDetails()

        model.setAnxiety(level)

        #expect(model.anxiety == kept)
    }

    /// Tapping the chosen level again takes it back, so a level picked by mistake needn't be saved.
    @Test
    func `picking the chosen level again clears it`() {
        let model = finishedModel()
        model.toggleDetails()
        model.pickAnxiety(6)
        #expect(model.anxiety == 6)

        model.pickAnxiety(6)

        #expect(model.anxiety == nil)
        model.pickAnxiety(3)
        #expect(model.anxiety == 3)
        model.pickAnxiety(8)
        #expect(model.anxiety == 8)
    }

    /// The row is 11 cells of equal width with 3-point gaps; a touch counts as the cell it's in, or, in a gap, the
    /// nearer
    /// one, and anything past an end as that end.
    @Test(arguments: [
        (0.0, 0), (24.0, 0), (25.9, 0), (26.5, 1), (150.0, 5), (299.0, 10), (-20.0, 0), (340.0, 10),
    ])
    func `a touch on the row counts as the cell under it`(x: Double, level: Int) {
        #expect(LogLoopViewModel.anxietyLevel(atX: x, rowWidth: 300, spacing: 3) == level)
    }

    /// VoiceOver moves through the levels one step at a time: up from "Not set" starts at 0, and down from 0 goes back
    /// to "Not set", as a second tap does on screen.
    @Test
    func `stepping through the levels starts at 0 and steps back to unset`() {
        let model = finishedModel()
        model.toggleDetails()

        model.stepAnxiety(by: 1)
        #expect(model.anxiety == 0)
        model.stepAnxiety(by: 1)
        #expect(model.anxiety == 1)
        model.stepAnxiety(by: -1)
        model.stepAnxiety(by: -1)
        #expect(model.anxiety == nil)
        model.stepAnxiety(by: -1)
        #expect(model.anxiety == nil)

        model.setAnxiety(10)
        model.stepAnxiety(by: 1)
        #expect(model.anxiety == 10)
    }

    @Test(arguments: [("  Before the 1:1 \n", "Before the 1:1"), ("   ", nil), ("", nil)])
    func `a note is saved trimmed, and a blank one isn't saved`(typed: String, saved: String?) throws {
        let model = finishedModel()
        model.toggleDetails()
        model.note = typed
        var stored: [Loop] = []

        model.save { stored.append($0) } history: { [$0] }

        #expect(try #require(stored.only).note == saved)
    }

    /// Closing the card is how the person says they don't want the details, so nothing hidden is saved.
    @Test
    func `closing the details drops the level and the note`() throws {
        let model = finishedModel()
        model.toggleDetails()
        model.setAnxiety(4)
        model.note = "Before the 1:1"

        model.toggleDetails()

        #expect(model.isShowingDetails == false)
        #expect(model.anxiety == nil)
        #expect(model.note.isEmpty)
        var stored: [Loop] = []
        model.save { stored.append($0) } history: { [$0] }
        let loop = try #require(stored.only)
        #expect(loop.anxiety == nil)
        #expect(loop.note == nil)
    }
}
