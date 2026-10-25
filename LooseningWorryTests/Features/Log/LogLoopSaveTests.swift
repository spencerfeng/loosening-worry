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

        model.save { stored.append($0) } loopsThisWeek: { 1 }

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

    @Test
    func `saving leads to Nice catch, showing the loop and this week's count`() throws {
        let model = finishedModel()

        model.save { _ in } loopsThisWeek: { 5 }

        let niceCatch = try #require(model.niceCatch)
        #expect(niceCatch.chips == ["News", "Scrolled", "More worry"])
        #expect(niceCatch.loopsThisWeek == 5)
    }

    /// The loop is saved either way, so the count it shows is at least that one.
    @Test
    func `if the week's count can't be read, Nice catch counts just the loop saved`() throws {
        struct CountFailed: Error {}
        let model = finishedModel()

        model.save { _ in } loopsThisWeek: { throw CountFailed() }

        #expect(try #require(model.niceCatch).loopsThisWeek == 1)
    }

    @Test
    func `an unfinished loop isn't saved`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        var stored: [Loop] = []

        model.save { stored.append($0) } loopsThisWeek: { 1 }

        #expect(stored.isEmpty)
        #expect(model.isSaved == false)
    }

    /// A second tap on Save, before the logger closes, must not log the loop twice.
    @Test
    func `saving twice stores the loop once`() {
        let model = finishedModel()
        var stored: [Loop] = []

        model.save { stored.append($0) } loopsThisWeek: { 1 }
        model.save { stored.append($0) } loopsThisWeek: { 1 }

        #expect(stored.count == 1)
        #expect(model.canSave == false)
    }

    @Test
    func `when saving fails, the person is told and can try again`() {
        struct SaveFailed: Error {}
        let model = finishedModel()

        model.save { _ in throw SaveFailed() } loopsThisWeek: { 1 }

        #expect(model.isSaved == false)
        #expect(model.saveFailed)
        #expect(model.canSave)

        var stored: [Loop] = []
        model.save { stored.append($0) } loopsThisWeek: { 1 }

        #expect(stored.count == 1)
        #expect(model.isSaved)
        #expect(model.saveFailed == false)
    }

    /// The message is about the loop as it was; once the person changes an answer it no longer applies.
    @Test
    func `reopening a step clears the message that saving failed`() {
        struct SaveFailed: Error {}
        let model = finishedModel()
        model.save { _ in throw SaveFailed() } loopsThisWeek: { 1 }

        model.goTo(.trigger)

        #expect(model.saveFailed == false)
    }
}

// MARK: - Details

@MainActor
struct LogLoopDetailsTests {
    /// A slider always shows a number, so opening the details must not record one the person never chose.
    @Test
    func `the anxiety level stays unset until the person sets it`() throws {
        let model = finishedModel()
        model.toggleDetails()
        #expect(model.isShowingDetails)
        #expect(model.anxiety == nil)

        model.setAnxiety(7)
        var stored: [Loop] = []
        model.save { stored.append($0) } loopsThisWeek: { 1 }

        #expect(try #require(stored.only).anxiety == 7)
    }

    @Test(arguments: [(-1, 0), (0, 0), (10, 10), (11, 10)])
    func `the anxiety level stays within 0 to 10`(level: Int, kept: Int) {
        let model = finishedModel()
        model.toggleDetails()

        model.setAnxiety(level)

        #expect(model.anxiety == kept)
    }

    @Test(arguments: [("  Before the 1:1 \n", "Before the 1:1"), ("   ", nil), ("", nil)])
    func `a note is saved trimmed, and a blank one isn't saved`(typed: String, saved: String?) throws {
        let model = finishedModel()
        model.toggleDetails()
        model.note = typed
        var stored: [Loop] = []

        model.save { stored.append($0) } loopsThisWeek: { 1 }

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
        model.save { stored.append($0) } loopsThisWeek: { 1 }
        let loop = try #require(stored.only)
        #expect(loop.anxiety == nil)
        #expect(loop.note == nil)
    }
}
