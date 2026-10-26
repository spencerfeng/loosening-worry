import Foundation
@testable import LooseningWorry
import Testing

@MainActor
struct EditOptionsViewModelTests {
    private func own(
        _ label: String,
        kind: OptionKind = .trigger,
        daysAgo: Double = 1,
        hidden: Bool = false,
    ) -> LoopOption {
        let option = LoopOption(kind: kind, label: label)
        option.createdAt = Date.now.addingTimeInterval(-daysAgo * 24 * 60 * 60)
        option.updatedAt = option.createdAt
        option.isHidden = hidden
        return option
    }

    @Test
    func `the triggers tab lists the person's own, newest first, then the starters`() {
        let saved = [own("Call from Mom", daysAgo: 30), own("Rent due", daysAgo: 2)]

        let sections = EditOptionsViewModel().sections(saved: saved)

        #expect(sections.map(\.kind) == [.yourOwn, .starters])
        #expect(sections[0].rows.map(\.label) == ["Rent due", "Call from Mom"])
        #expect(sections[1].rows.map(\.choice.starterID) == StarterOption.options(for: .trigger).map(\.id))
        #expect(sections.flatMap(\.rows).allSatisfy { $0.action == .remove })
    }

    /// Step 3's core results can't be removed, so they're shown locked.
    @Test
    func `the results tab lists the core results, locked`() {
        let model = EditOptionsViewModel()
        model.select(.result)

        let sections = model.sections(saved: [own("Felt numb", kind: .result)])

        #expect(sections.map(\.kind) == [.yourOwn, .coreResults])
        #expect(sections[1].rows.allSatisfy { $0.action == .locked && $0.note == .coreResult })
        #expect(sections[0].rows.map(\.action) == [.remove])
    }

    @Test
    func `removed options are listed last, saying whose they were, ready to restore`() {
        let news = LoopOption(overriding: .news, label: "News")
        news.isHidden = true
        let saved = [own("Rent due", hidden: true), news]

        let sections = EditOptionsViewModel().sections(saved: saved)

        let removed = sections.last
        #expect(removed?.kind == .removed(count: 2))
        #expect(removed?.rows.map(\.label) == ["News", "Rent due"])
        #expect(removed?.rows.map(\.note) == [.starter, .yourOwn])
        #expect(removed?.rows.allSatisfy { $0.action == .restore(isEnabled: true) } == true)
        #expect(!sections[0].rows.contains { $0.label == "News" })
    }

    /// Restoring would list the text twice, so the button is off until the other one goes.
    @Test
    func `a removed option can't be restored while another shows its text`() {
        let saved = [own("Rent due", daysAgo: 5, hidden: true), own("Rent due")]

        let removed = EditOptionsViewModel().sections(saved: saved).last

        #expect(removed?.rows.map(\.action) == [.restore(isEnabled: false)])
    }

    // MARK: - Adding

    @Test(arguments: ["", "   "])
    func `adding nothing asks for a name`(draft: String) {
        let model = EditOptionsViewModel()
        model.startAdding()
        model.draft = draft
        var added: [String] = []

        model.add(saved: []) { added.append($0) }

        #expect(added.isEmpty)
        #expect(model.addError == .empty)
        #expect(model.isAdding)
    }

    /// The same check as the logger's add-your-own: exact text, case and inner spaces included, after trimming.
    @Test
    func `adding text that's already showing says so`() {
        let model = EditOptionsViewModel()
        model.startAdding()
        model.draft = " News "

        model.add(saved: []) { _ in }

        #expect(model.addError == .alreadyShowing("News"))
    }

    @Test
    func `adding text that's been removed says to restore it instead`() {
        let model = EditOptionsViewModel()
        model.startAdding()
        model.draft = "Rent due"

        model.add(saved: [own("Rent due", hidden: true)]) { _ in }

        #expect(model.addError == .removed("Rent due"))
    }

    @Test
    func `adding new text saves it, trimmed, and closes the card`() {
        let model = EditOptionsViewModel()
        model.startAdding()
        model.draft = "  Rent due "
        var added: [String] = []

        model.add(saved: []) { added.append($0) }

        #expect(added == ["Rent due"])
        #expect(model.isAdding == false)
        #expect(model.draft.isEmpty)
        #expect(model.addError == nil)
    }

    @Test
    func `if saving fails, the card stays open and says so`() {
        struct SaveFailed: Error {}
        let model = EditOptionsViewModel()
        model.startAdding()
        model.draft = "Rent due"

        model.add(saved: []) { _ in throw SaveFailed() }

        #expect(model.isAdding)
        #expect(model.addError == .saveFailed)
    }

    @Test
    func `typing again clears the message, and switching tabs closes the card`() {
        let model = EditOptionsViewModel()
        model.startAdding()
        model.add(saved: []) { _ in }
        #expect(model.addError == .empty)

        model.draft = "R"
        #expect(model.addError == nil)

        model.select(.behavior)
        #expect(model.isAdding == false)
        #expect(model.kind == .behavior)
    }

    /// The text field writes its text back even when nothing changed; only real typing clears the message.
    @Test
    func `the message stays until the text changes`() {
        let model = EditOptionsViewModel()
        model.startAdding()
        model.draft = "Money"
        model.add(saved: []) { _ in }

        model.draft = "Money"

        #expect(model.addError == .alreadyShowing("Money"))
    }

    @Test
    func `the screen opens on the tab it was opened from`() {
        #expect(EditOptionsViewModel(kind: .behavior).kind == .behavior)
    }

    // MARK: - Removing and restoring

    @Test
    func `if removing fails, the screen says so`() {
        struct SaveFailed: Error {}
        let model = EditOptionsViewModel()

        model.remove(OptionChoice(.news, label: "News")) { _ in throw SaveFailed() }

        #expect(model.editError == .removeFailed)
    }

    @Test
    func `if restoring fails, the screen says so, and the next change that works clears it`() {
        struct SaveFailed: Error {}
        let model = EditOptionsViewModel()
        let news = OptionChoice(.news, label: "News")

        model.restore(news) { _ in throw SaveFailed() }
        #expect(model.editError == .restoreFailed)

        var removed: [OptionChoice] = []
        model.remove(news) { removed.append($0) }

        #expect(removed == [news])
        #expect(model.editError == nil)
    }
}
