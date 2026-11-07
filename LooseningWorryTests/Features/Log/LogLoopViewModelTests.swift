@testable import LooseningWorry
import Testing

/// Stands in for the option store: records each option the logger asks to save and hands back a saved choice.
final class SavedOptions {
    private(set) var labels: [String] = []
    private(set) var kinds: [OptionKind] = []

    func save(_ kind: OptionKind, _ label: String) -> OptionChoice {
        kinds.append(kind)
        labels.append(label)
        return OptionChoice(id: "custom.saved", label: label)
    }
}

/// Choices the tests pick, as the logger would offer them.
extension OptionChoice {
    static let news = OptionChoice(.news, label: "News")
    static let deadline = OptionChoice(.deadline, label: "Deadline")
    static let scrolled = OptionChoice(.scrolled, label: "Scrolled")
    static let moreWorry = OptionChoice(.moreWorry, label: "More worry")
}

@MainActor
struct LogLoopViewModelTests {
    /// The saved loop counts each answer by its id, so the logger keeps the whole choice, not just its text.
    @Test
    func `picking keeps the chosen option, id and all`() {
        let model = LogLoopViewModel()
        let own = OptionChoice(LoopOption(kind: .trigger, label: "Rent due"))

        model.pick(own)
        model.pick(.scrolled)

        #expect(model.answer(for: .trigger) == own)
        #expect(model.answer(for: .behavior)?.id == "behavior.scrolled")
    }

    @Test
    func `the steps are numbered trigger, behavior, result`() {
        #expect(OptionKind.loopSteps.map(\.stepNumber) == [1, 2, 3])
        #expect(OptionKind.loopSteps == [.trigger, .behavior, .result])
    }

    @Test
    func `at the start the trigger step is current and the others are upcoming`() {
        let model = LogLoopViewModel()

        #expect(OptionKind.loopSteps.map(model.progress(for:)) == [.current, .upcoming, .upcoming])
    }

    @Test
    func `answered steps show as answered, and as reopened when tapped again`() {
        let model = LogLoopViewModel()
        model.pick(.news)

        #expect(OptionKind.loopSteps.map(model.progress(for:)) == [.answered, .current, .upcoming])

        model.goTo(.trigger)

        #expect(OptionKind.loopSteps.map(model.progress(for:)) == [.reopened, .upcoming, .upcoming])
    }

    @Test(arguments: [(StepProgress.current, true), (.reopened, true), (.answered, false), (.upcoming, false)])
    func `only a step being asked counts as current`(progress: StepProgress, isCurrent: Bool) {
        #expect(progress.isCurrent == isCurrent)
    }

    /// The summary card pops the row just answered, and only that one.
    @Test
    func `each pick pops the row it answered`() {
        let model = LogLoopViewModel()
        #expect(OptionKind.loopSteps.allSatisfy { model.popTrigger(for: $0) == nil })

        model.pick(.news)
        #expect(model.popTrigger(for: .trigger) != nil)
        #expect(model.popTrigger(for: .behavior) == nil)

        model.pick(.scrolled)
        #expect(model.popTrigger(for: .trigger) == nil)
        #expect(model.popTrigger(for: .behavior) != nil)
    }

    /// The pop and the haptic replay when the trigger changes, so answering a reopened step again pops it again.
    @Test
    func `re-answering a reopened step pops it again`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        let first = model.popTrigger(for: .trigger)
        model.goTo(.trigger)

        model.pick(.deadline)

        #expect(model.popTrigger(for: .trigger) != nil)
        #expect(model.popTrigger(for: .trigger) != first)
    }

    /// Reopening a step is not an answer, so it mustn't replay or move the pop.
    @Test
    func `reopening a step keeps the last pop`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.pick(.scrolled)
        let pop = model.popTrigger(for: .behavior)

        model.goTo(.trigger)

        #expect(model.popTrigger(for: .behavior) == pop)
        #expect(model.popTrigger(for: .trigger) == nil)
    }

    @Test
    func `starts on the trigger step with nothing answered`() {
        let model = LogLoopViewModel()

        #expect(model.currentStep == .trigger)
        #expect(OptionKind.loopSteps.allSatisfy { model.answer(for: $0) == nil })
    }

    @Test
    func `picking an option answers the current step and moves to the next`() {
        let model = LogLoopViewModel()

        model.pick(.news)

        #expect(model.answer(for: .trigger)?.label == "News")
        #expect(model.currentStep == .behavior)

        model.pick(.scrolled)

        #expect(model.answer(for: .behavior)?.label == "Scrolled")
        #expect(model.currentStep == .result)
    }

    @Test
    func `picking the result finishes the loop`() {
        let model = LogLoopViewModel()

        model.pick(.news)
        model.pick(.scrolled)
        model.pick(.moreWorry)

        #expect(model.answer(for: .result)?.label == "More worry")
        #expect(model.currentStep == nil)
    }

    @Test
    func `going back to an answered step keeps its answer`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.pick(.scrolled)

        model.goTo(.trigger)

        #expect(model.currentStep == .trigger)
        #expect(model.answer(for: .trigger)?.label == "News")
        #expect(model.answer(for: .behavior)?.label == "Scrolled")
    }

    @Test
    func `changing an earlier answer skips to the first step still unanswered`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.pick(.scrolled)
        model.goTo(.trigger)

        model.pick(.deadline)

        #expect(model.answer(for: .trigger)?.label == "Deadline")
        #expect(model.currentStep == .result)
    }

    @Test
    func `changing an answer once all three are answered finishes the loop again`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.pick(.scrolled)
        model.pick(.moreWorry)
        model.goTo(.trigger)

        model.pick(.deadline)

        #expect(model.answer(for: .trigger)?.label == "Deadline")
        #expect(model.currentStep == nil)
    }

    @Test
    func `once the loop is finished, a stray pick changes nothing`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.pick(.scrolled)
        model.pick(.moreWorry)

        model.pick(.deadline)

        #expect(model.answer(for: .trigger)?.label == "News")
        #expect(model.answer(for: .behavior)?.label == "Scrolled")
        #expect(model.answer(for: .result)?.label == "More worry")
        #expect(model.currentStep == nil)
    }
}

// MARK: - Add your own

@MainActor
struct LogLoopAddOwnTests {
    @Test
    func `the add-your-own field opens and closes, and closing clears the draft`() {
        let model = LogLoopViewModel()
        #expect(model.ownDraft.isOpen == false)

        model.ownDraft.toggle()
        model.ownDraft.text = "Rent due"
        #expect(model.ownDraft.isOpen)

        model.ownDraft.toggle()
        #expect(model.ownDraft.isOpen == false)
        #expect(model.ownDraft.text.isEmpty)
    }

    @Test
    func `adding new text saves it and picks it`() {
        let model = LogLoopViewModel()
        let saved = SavedOptions()
        model.ownDraft.toggle()
        model.ownDraft.text = "Rent due"

        model.addOwn(existing: [OptionChoice(.news, label: "News")], save: saved.save)

        #expect(saved.labels == ["Rent due"])
        // The loop counts it by the id the saved option got.
        #expect(model.answer(for: .trigger) == OptionChoice(id: "custom.saved", label: "Rent due"))
        #expect(model.currentStep == .behavior)
        #expect(model.ownDraft.isOpen == false)
        #expect(model.ownDraft.text.isEmpty)
    }

    @Test
    func `adding text that matches an option exactly picks it without saving a duplicate`() {
        let model = LogLoopViewModel()
        let saved = SavedOptions()
        model.ownDraft.toggle()
        model.ownDraft.text = "News"

        model.addOwn(existing: [OptionChoice(.news, label: "News")], save: saved.save)

        #expect(saved.labels.isEmpty)
        #expect(model.answer(for: .trigger) == OptionChoice(.news, label: "News"))
        #expect(model.currentStep == .behavior)
    }

    @Test
    func `text that differs from an option only in case is a new option`() {
        let model = LogLoopViewModel()
        let saved = SavedOptions()
        model.ownDraft.toggle()
        model.ownDraft.text = "news"

        model.addOwn(existing: [OptionChoice(.news, label: "News")], save: saved.save)

        #expect(saved.labels == ["news"])
        #expect(model.answer(for: .trigger)?.label == "news")
    }

    @Test
    func `spaces around the text are trimmed before it is matched or saved`() {
        let model = LogLoopViewModel()
        let saved = SavedOptions()
        let existing = [OptionChoice(.news, label: "News")]

        model.ownDraft.toggle()
        model.ownDraft.text = "  News "
        model.addOwn(existing: existing, save: saved.save)
        #expect(saved.labels.isEmpty)
        #expect(model.answer(for: .trigger)?.label == "News")

        model.ownDraft.toggle()
        model.ownDraft.text = " Paced around\n"
        model.addOwn(existing: existing, save: saved.save)
        #expect(saved.labels == ["Paced around"])
        #expect(model.answer(for: .behavior)?.label == "Paced around")
    }

    @Test(arguments: ["", "   ", "\n"])
    func `blank text adds nothing and keeps the field open`(draft: String) {
        let model = LogLoopViewModel()
        let saved = SavedOptions()
        model.ownDraft.toggle()
        model.ownDraft.text = draft

        model.addOwn(existing: [], save: saved.save)

        #expect(saved.labels.isEmpty)
        #expect(model.answer(for: .trigger) == nil)
        #expect(model.ownDraft.isOpen)
    }

    @Test
    func `picking a chip closes the field and drops the draft`() {
        let model = LogLoopViewModel()
        model.ownDraft.toggle()
        model.ownDraft.text = "Rent"

        model.pick(.news)

        #expect(model.ownDraft.isOpen == false)
        #expect(model.ownDraft.text.isEmpty)
    }

    @Test
    func `reopening a step closes the field and drops the draft`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.ownDraft.toggle()
        model.ownDraft.text = "Paced"

        model.goTo(.trigger)

        #expect(model.ownDraft.isOpen == false)
        #expect(model.ownDraft.text.isEmpty)
    }

    @Test(arguments: [("", false), ("  ", false), ("Rent", true), (" Rent ", true)])
    func `adding is possible only once something is typed`(draft: String, canAdd: Bool) {
        let model = LogLoopViewModel()
        model.ownDraft.toggle()

        model.ownDraft.text = draft

        #expect(model.ownDraft.canAdd == canAdd)
    }

    @Test
    func `a new option is saved under the step being asked`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        let saved = SavedOptions()
        model.ownDraft.toggle()
        model.ownDraft.text = "Paced around"

        model.addOwn(existing: [], save: saved.save)

        #expect(saved.kinds == [.behavior])
    }

    @Test
    func `nothing is added once the loop is finished`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.pick(.scrolled)
        model.pick(.moreWorry)
        let saved = SavedOptions()
        model.ownDraft.toggle()
        model.ownDraft.text = "Rent due"

        model.addOwn(existing: [], save: saved.save)

        #expect(saved.labels.isEmpty)
    }

    @Test
    func `spaces inside the text count when matching`() {
        let model = LogLoopViewModel()
        let saved = SavedOptions()
        model.ownDraft.toggle()
        model.ownDraft.text = "Social  plans"

        model.addOwn(existing: [OptionChoice(.socialPlans, label: "Social plans")], save: saved.save)

        #expect(saved.labels == ["Social  plans"])
    }

    /// A failed save loses only the option for next time; the loop still gets the answer.
    @Test
    func `when saving fails, the text is still picked and the person is told it wasn't kept`() {
        struct SaveFailed: Error {}
        let model = LogLoopViewModel()
        model.ownDraft.toggle()
        model.ownDraft.text = "Rent due"

        model.addOwn(existing: []) { _, _ in throw SaveFailed() }

        #expect(model.answer(for: .trigger)?.label == "Rent due")
        // No option was saved, so the loop gets an id of its own, matching no option.
        #expect(model.answer(for: .trigger)?.id.hasPrefix("custom.") == true)
        #expect(model.currentStep == .behavior)
        #expect(model.ownDraft.unsavedLabel == "Rent due")
    }

    enum NextAction: CaseIterable { case pick, reopen, openField }

    @Test(arguments: NextAction.allCases)
    func `the note that an option wasn't kept goes once the person moves on`(next: NextAction) {
        struct SaveFailed: Error {}
        let model = LogLoopViewModel()
        model.ownDraft.toggle()
        model.ownDraft.text = "Rent due"
        model.addOwn(existing: []) { _, _ in throw SaveFailed() }

        switch next {
        case .pick: model.pick(.scrolled)
        case .reopen: model.goTo(.trigger)
        case .openField: model.ownDraft.toggle()
        }

        #expect(model.ownDraft.unsavedLabel == nil)
    }
}
