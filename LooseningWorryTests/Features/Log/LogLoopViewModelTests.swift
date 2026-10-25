@testable import LooseningWorry
import Testing

@MainActor
struct LogLoopViewModelTests {
    @Test
    func `the steps are numbered trigger, behavior, result`() {
        #expect(OptionKind.allCases.map(\.stepNumber) == [1, 2, 3])
        #expect(OptionKind.allCases == [.trigger, .behavior, .result])
    }

    @Test
    func `at the start the trigger step is current and the others are upcoming`() {
        let model = LogLoopViewModel()

        #expect(OptionKind.allCases.map(model.progress(for:)) == [.current, .upcoming, .upcoming])
    }

    @Test
    func `answered steps show as answered, and as reopened when tapped again`() {
        let model = LogLoopViewModel()
        model.pick("News")

        #expect(OptionKind.allCases.map(model.progress(for:)) == [.answered, .current, .upcoming])

        model.goTo(.trigger)

        #expect(OptionKind.allCases.map(model.progress(for:)) == [.reopened, .upcoming, .upcoming])
    }

    @Test(arguments: [(StepProgress.current, true), (.reopened, true), (.answered, false), (.upcoming, false)])
    func `only a step being asked counts as current`(progress: StepProgress, isCurrent: Bool) {
        #expect(progress.isCurrent == isCurrent)
    }

    @Test
    func `each pick cheers the step it answered`() {
        let model = LogLoopViewModel()
        #expect(model.cheer == nil)

        model.pick("News")
        #expect(model.cheer?.step == .trigger)

        model.pick("Scrolled")
        #expect(model.cheer?.step == .behavior)
    }

    @Test(arguments: [0, 1, 7])
    func `every cheer in a loop knows how many loops came before it`(loopsLogged: Int) {
        let model = LogLoopViewModel(loopsLogged: loopsLogged)

        model.pick("News")
        #expect(model.cheer?.loopsLogged == loopsLogged)

        model.pick("Scrolled")
        #expect(model.cheer?.loopsLogged == loopsLogged)
    }

    /// The logger reads the count once it opens, after the model exists.
    @Test
    func `a loop count set after opening applies to the cheers`() {
        let model = LogLoopViewModel()

        model.loopsLogged = 4
        model.pick("News")

        #expect(model.cheer?.loopsLogged == 4)
    }

    /// The badge and the VoiceOver announcement only refresh when the cheer changes.
    @Test
    func `every pick is counted, so re-answering a reopened step still cheers again`() {
        let model = LogLoopViewModel()
        #expect(model.pickCount == 0)
        model.pick("News")
        model.goTo(.trigger)

        model.pick("Deadline")

        #expect(model.cheer?.step == .trigger)
        #expect(model.pickCount == 2)
    }

    @Test
    func `reopening a step keeps the last cheer`() {
        let model = LogLoopViewModel()
        model.pick("News")
        model.pick("Scrolled")
        let cheer = model.cheer

        model.goTo(.trigger)

        #expect(model.cheer == cheer)
    }

    @Test
    func `starts on the trigger step with nothing answered`() {
        let model = LogLoopViewModel()

        #expect(model.currentStep == .trigger)
        #expect(OptionKind.allCases.allSatisfy { model.answer(for: $0) == nil })
    }

    @Test
    func `picking an option answers the current step and moves to the next`() {
        let model = LogLoopViewModel()

        model.pick("News")

        #expect(model.answer(for: .trigger) == "News")
        #expect(model.currentStep == .behavior)

        model.pick("Scrolled")

        #expect(model.answer(for: .behavior) == "Scrolled")
        #expect(model.currentStep == .result)
    }

    @Test
    func `picking the result finishes the loop`() {
        let model = LogLoopViewModel()

        model.pick("News")
        model.pick("Scrolled")
        model.pick("More worry")

        #expect(model.answer(for: .result) == "More worry")
        #expect(model.currentStep == nil)
    }

    @Test
    func `going back to an answered step keeps its answer`() {
        let model = LogLoopViewModel()
        model.pick("News")
        model.pick("Scrolled")

        model.goTo(.trigger)

        #expect(model.currentStep == .trigger)
        #expect(model.answer(for: .trigger) == "News")
        #expect(model.answer(for: .behavior) == "Scrolled")
    }

    @Test
    func `changing an earlier answer skips to the first step still unanswered`() {
        let model = LogLoopViewModel()
        model.pick("News")
        model.pick("Scrolled")
        model.goTo(.trigger)

        model.pick("Deadline")

        #expect(model.answer(for: .trigger) == "Deadline")
        #expect(model.currentStep == .result)
    }

    @Test
    func `changing an answer once all three are answered finishes the loop again`() {
        let model = LogLoopViewModel()
        model.pick("News")
        model.pick("Scrolled")
        model.pick("More worry")
        model.goTo(.trigger)

        model.pick("Deadline")

        #expect(model.answer(for: .trigger) == "Deadline")
        #expect(model.currentStep == nil)
    }

    @Test
    func `once the loop is finished, a stray pick changes nothing`() {
        let model = LogLoopViewModel()
        model.pick("News")
        model.pick("Scrolled")
        model.pick("More worry")

        model.pick("Deadline")

        #expect(model.answer(for: .trigger) == "News")
        #expect(model.answer(for: .behavior) == "Scrolled")
        #expect(model.answer(for: .result) == "More worry")
        #expect(model.currentStep == nil)
    }
}

// MARK: - Add your own

@MainActor
struct LogLoopAddOwnTests {
    @Test
    func `the add-your-own field opens and closes, and closing clears the draft`() {
        let model = LogLoopViewModel()
        #expect(model.isAddingOwn == false)

        model.toggleAddOwn()
        model.draft = "Rent due"
        #expect(model.isAddingOwn)

        model.toggleAddOwn()
        #expect(model.isAddingOwn == false)
        #expect(model.draft.isEmpty)
    }

    @Test
    func `adding new text saves it and picks it`() {
        let model = LogLoopViewModel()
        var saved: [String] = []
        model.toggleAddOwn()
        model.draft = "Rent due"

        model.addOwn(existing: [OptionChoice(label: "News", starterID: "trigger.news")]) { saved.append($1) }

        #expect(saved == ["Rent due"])
        #expect(model.answer(for: .trigger) == "Rent due")
        #expect(model.currentStep == .behavior)
        #expect(model.isAddingOwn == false)
        #expect(model.draft.isEmpty)
    }

    @Test
    func `adding text that matches an option exactly picks it without saving a duplicate`() {
        let model = LogLoopViewModel()
        var saved: [String] = []
        model.toggleAddOwn()
        model.draft = "News"

        model.addOwn(existing: [OptionChoice(label: "News", starterID: "trigger.news")]) { saved.append($1) }

        #expect(saved.isEmpty)
        #expect(model.answer(for: .trigger) == "News")
        #expect(model.currentStep == .behavior)
    }

    @Test
    func `text that differs from an option only in case is a new option`() {
        let model = LogLoopViewModel()
        var saved: [String] = []
        model.toggleAddOwn()
        model.draft = "news"

        model.addOwn(existing: [OptionChoice(label: "News", starterID: "trigger.news")]) { saved.append($1) }

        #expect(saved == ["news"])
        #expect(model.answer(for: .trigger) == "news")
    }

    @Test
    func `spaces around the text are trimmed before it is matched or saved`() {
        let model = LogLoopViewModel()
        var saved: [String] = []
        let existing = [OptionChoice(label: "News", starterID: "trigger.news")]

        model.toggleAddOwn()
        model.draft = "  News "
        model.addOwn(existing: existing) { saved.append($1) }
        #expect(saved.isEmpty)
        #expect(model.answer(for: .trigger) == "News")

        model.toggleAddOwn()
        model.draft = " Paced around\n"
        model.addOwn(existing: existing) { saved.append($1) }
        #expect(saved == ["Paced around"])
        #expect(model.answer(for: .behavior) == "Paced around")
    }

    @Test(arguments: ["", "   ", "\n"])
    func `blank text adds nothing and keeps the field open`(draft: String) {
        let model = LogLoopViewModel()
        var saved: [String] = []
        model.toggleAddOwn()
        model.draft = draft

        model.addOwn(existing: []) { saved.append($1) }

        #expect(saved.isEmpty)
        #expect(model.answer(for: .trigger) == nil)
        #expect(model.isAddingOwn)
    }

    @Test
    func `picking a chip closes the field and drops the draft`() {
        let model = LogLoopViewModel()
        model.toggleAddOwn()
        model.draft = "Rent"

        model.pick("News")

        #expect(model.isAddingOwn == false)
        #expect(model.draft.isEmpty)
    }

    @Test
    func `reopening a step closes the field and drops the draft`() {
        let model = LogLoopViewModel()
        model.pick("News")
        model.toggleAddOwn()
        model.draft = "Paced"

        model.goTo(.trigger)

        #expect(model.isAddingOwn == false)
        #expect(model.draft.isEmpty)
    }

    @Test(arguments: [("", false), ("  ", false), ("Rent", true), (" Rent ", true)])
    func `adding is possible only once something is typed`(draft: String, canAdd: Bool) {
        let model = LogLoopViewModel()
        model.toggleAddOwn()

        model.draft = draft

        #expect(model.canAddOwn == canAdd)
    }

    @Test
    func `a new option is saved under the step being asked`() {
        let model = LogLoopViewModel()
        model.pick("News")
        var savedKinds: [OptionKind] = []
        model.toggleAddOwn()
        model.draft = "Paced around"

        model.addOwn(existing: []) { kind, _ in savedKinds.append(kind) }

        #expect(savedKinds == [.behavior])
    }

    @Test
    func `nothing is added once the loop is finished`() {
        let model = LogLoopViewModel()
        model.pick("News")
        model.pick("Scrolled")
        model.pick("More worry")
        var saved: [String] = []
        model.toggleAddOwn()
        model.draft = "Rent due"

        model.addOwn(existing: []) { saved.append($1) }

        #expect(saved.isEmpty)
    }

    @Test
    func `spaces inside the text count when matching`() {
        let model = LogLoopViewModel()
        var saved: [String] = []
        model.toggleAddOwn()
        model.draft = "Social  plans"

        model.addOwn(existing: [OptionChoice(label: "Social plans", starterID: "trigger.socialPlans")]) {
            saved.append($1)
        }

        #expect(saved == ["Social  plans"])
    }

    /// A failed save loses only the option for next time; the loop still gets the answer.
    @Test
    func `when saving fails, the text is still picked and the person is told it wasn't kept`() {
        struct SaveFailed: Error {}
        let model = LogLoopViewModel()
        model.toggleAddOwn()
        model.draft = "Rent due"

        model.addOwn(existing: []) { _, _ in throw SaveFailed() }

        #expect(model.answer(for: .trigger) == "Rent due")
        #expect(model.currentStep == .behavior)
        #expect(model.unsavedOption == "Rent due")
    }

    enum NextAction: CaseIterable { case pick, reopen, openField }

    @Test(arguments: NextAction.allCases)
    func `the note that an option wasn't kept goes once the person moves on`(next: NextAction) {
        struct SaveFailed: Error {}
        let model = LogLoopViewModel()
        model.toggleAddOwn()
        model.draft = "Rent due"
        model.addOwn(existing: []) { _, _ in throw SaveFailed() }

        switch next {
        case .pick: model.pick("Scrolled")
        case .reopen: model.goTo(.trigger)
        case .openField: model.toggleAddOwn()
        }

        #expect(model.unsavedOption == nil)
    }
}
