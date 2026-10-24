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
