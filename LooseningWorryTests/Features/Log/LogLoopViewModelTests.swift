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
