@testable import LooseningWorry
import Testing

private struct InterpreterFailed: Error {}

/// Describing a loop in words: the interpreter reads the sentence, and the logger fills in the steps from it.
@MainActor
struct LogDescribeTests {
    @Test
    func `tapping Fill in picks what was read and moves to the first step left empty`() async {
        let interpreter = FakeLoopInterpreter(reading: LoopReading(picks: [
            .trigger: "trigger.work",
            .result: "result.moreWorry",
        ]))
        let model = LogLoopViewModel(interpreter: interpreter)
        model.described = "My boss emailed at 9pm and I felt worse."

        await model.fillIn(saved: [])

        #expect(model.answer(for: .trigger) == OptionChoice(.work, label: "Work"))
        #expect(model.answer(for: .behavior) == nil)
        #expect(model.answer(for: .result)?.id == "result.moreWorry")
        #expect(model.currentStep == .behavior)
    }

    @Test
    func `filled-in picks show as suggested until the person picks something else`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(picks: [
            .trigger: "trigger.work",
            .behavior: "behavior.keptChecking",
        ])))
        model.described = "Work email again, kept checking it."

        await model.fillIn(saved: [])

        #expect(model.isSuggested(.trigger))
        #expect(model.isSuggested(.behavior))
        #expect(!model.isSuggested(.result))

        model.goTo(.trigger)
        model.pick(.deadline)

        #expect(!model.isSuggested(.trigger))
        #expect(model.isSuggested(.behavior))
    }

    /// Guided generation keeps the model to the person's ids; this is the safety net if one slips through, or names an
    /// option removed since.
    @Test
    func `an id that isn't one of the person's options is left unpicked`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(picks: [
            .trigger: "trigger.landlord",
            .behavior: "result.moreWorry",
        ])))
        model.described = "My landlord texted again."

        await model.fillIn(saved: [])

        #expect(model.answer(for: .trigger) == nil)
        #expect(model.answer(for: .behavior) == nil)
        #expect(!model.isSuggested(.trigger))
        #expect(!model.isSuggested(.behavior))
        #expect(model.currentStep == .trigger)
    }

    @Test
    func `a new option from the person's words is offered, and saved and picked only when tapped`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(
            picks: [.behavior: "behavior.keptChecking"],
            newOptions: [.trigger: "Landlord"],
        )))
        model.described = "My landlord texted again and I kept checking my phone."
        let saved = SavedOptions()

        await model.fillIn(saved: [])

        #expect(model.suggestedOption(for: .trigger) == "Landlord")
        #expect(model.answer(for: .trigger) == nil)
        #expect(saved.labels.isEmpty)

        model.addSuggestedOption(existing: [], save: saved.save)

        #expect(saved.labels == ["Landlord"])
        #expect(saved.kinds == [.trigger])
        #expect(model.answer(for: .trigger)?.label == "Landlord")
        #expect(model.suggestedOption(for: .trigger) == nil)
    }

    @Test
    func `a suggested new option goes once the person picks something else for that step`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(newOptions: [
            .trigger: "Landlord"
        ])))
        model.described = "My landlord texted again."

        await model.fillIn(saved: [])
        model.pick(.news)

        #expect(model.suggestedOption(for: .trigger) == nil)
    }

    @Test
    func `nothing read says it couldn't tell, and leaves the steps to pick`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(picks: [
            .trigger: "trigger.notAnOption"
        ])))
        model.described = "ugh, today"

        await model.fillIn(saved: [])

        #expect(model.couldntTell)
        #expect(model.currentStep == .trigger)
        #expect(model.described == "ugh, today")
    }

    @Test
    func `the interpreter failing says it couldn't tell`() async {
        let interpreter = FakeLoopInterpreter()
        interpreter.error = InterpreterFailed()
        let model = LogLoopViewModel(interpreter: interpreter)
        model.described = "Work email again, kept checking it."

        await model.fillIn(saved: [])

        #expect(model.couldntTell)
        #expect(model.answer(for: .trigger) == nil)
    }

    @Test
    func `a new option alone is something read`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(newOptions: [
            .trigger: "Landlord"
        ])))
        model.described = "My landlord texted again."

        await model.fillIn(saved: [])

        #expect(!model.couldntTell)
    }

    @Test
    func `trying again clears couldn't tell`() async {
        let interpreter = FakeLoopInterpreter()
        let model = LogLoopViewModel(interpreter: interpreter)
        model.described = "ugh, today"
        await model.fillIn(saved: [])

        interpreter.reading = LoopReading(picks: [.trigger: "trigger.work"])
        model.described = "Work email again."
        await model.fillIn(saved: [])

        #expect(!model.couldntTell)
    }

    @Test
    func `while filling in, it shows it's working and a second tap does nothing`() async {
        let interpreter = FakeLoopInterpreter(reading: LoopReading(picks: [.trigger: "trigger.work"]))
        interpreter.isHeld = true
        let model = LogLoopViewModel(interpreter: interpreter)
        model.described = "Work email again."
        #expect(!model.isFillingIn)

        let first = Task { await model.fillIn(saved: []) }
        await interpreter.untilHeld()
        #expect(model.isFillingIn)

        await model.fillIn(saved: [])
        #expect(interpreter.asked.count == 1)

        interpreter.release()
        await first.value
        #expect(!model.isFillingIn)
        #expect(model.answer(for: .trigger)?.id == "trigger.work")
    }

    @Test
    func `blank words aren't read`() async {
        let interpreter = FakeLoopInterpreter()
        let model = LogLoopViewModel(interpreter: interpreter)
        model.described = "  \n "

        #expect(!model.canFillIn)
        await model.fillIn(saved: [])

        #expect(interpreter.asked.isEmpty)
        #expect(!model.couldntTell)
    }

    @Test
    func `crisis wording points to Help as it's typed, and still after Fill in`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(picks: [
            .trigger: "trigger.work"
        ])))
        model.described = "Work again. I can't go on like this."
        #expect(model.showsHelp)

        await model.fillIn(saved: [])

        #expect(model.showsHelp)
    }

    @Test
    func `everyday words don't point to Help`() {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter())
        model.described = "Work email again, kept checking it."

        #expect(!model.showsHelp)
    }

    @Test
    func `the field shows at the start only where the interpreter can read`() {
        let interpreter = FakeLoopInterpreter()
        #expect(LogLoopViewModel(interpreter: interpreter).showsDescribe)

        interpreter.isAvailable = false
        #expect(!LogLoopViewModel(interpreter: interpreter).showsDescribe)
        #expect(!LogLoopViewModel().showsDescribe)
    }

    @Test
    func `the field goes once a step is picked, and comes back on step 1 with nothing picked`() {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter())

        model.pick(.news)
        #expect(!model.showsDescribe)

        model.goTo(.trigger)
        #expect(!model.showsDescribe)

        let fresh = LogLoopViewModel(interpreter: FakeLoopInterpreter())
        fresh.goTo(.behavior)
        #expect(!fresh.showsDescribe)
        fresh.goTo(.trigger)
        #expect(fresh.showsDescribe)
    }

    @Test
    func `after Fill in reads something the field goes and the words are cleared`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(newOptions: [
            .trigger: "Landlord"
        ])))
        model.described = "My landlord texted again."

        await model.fillIn(saved: [])

        #expect(!model.showsDescribe)
        #expect(model.described.isEmpty)
    }

    @Test
    func `when it couldn't tell the field stays, words and all`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter())
        model.described = "ugh, today"

        await model.fillIn(saved: [])

        #expect(model.showsDescribe)
        #expect(model.described == "ugh, today")
    }

    @Test
    func `the Help line stays once the words that called for it are cleared`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(picks: [
            .trigger: "trigger.work"
        ])))
        model.described = "Work again. I can't go on like this."

        await model.fillIn(saved: [])

        #expect(model.described.isEmpty)
        #expect(model.showsHelp)
    }

    @Test
    func `a suggested option matching a choice picks that choice instead of saving a twin`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(newOptions: [
            .trigger: "News"
        ])))
        model.described = "Saw the news again."
        let saved = SavedOptions()
        await model.fillIn(saved: [])

        model.addSuggestedOption(existing: [.news, .deadline], save: saved.save)

        #expect(saved.labels.isEmpty)
        #expect(model.answer(for: .trigger) == .news)
    }

    @Test
    func `a suggested option that can't be saved is still picked, with a note`() async {
        struct Failed: Error {}
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(newOptions: [
            .trigger: "Landlord"
        ])))
        model.described = "My landlord texted again."
        await model.fillIn(saved: [])

        model.addSuggestedOption(existing: []) { _, _ in throw Failed() }

        #expect(model.answer(for: .trigger)?.label == "Landlord")
        #expect(model.unsavedOption == "Landlord")
    }

    @Test
    func `adding a suggested option with none offered does nothing`() {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter())
        let saved = SavedOptions()

        model.addSuggestedOption(existing: [], save: saved.save)

        #expect(saved.labels.isEmpty)
        #expect(model.answer(for: .trigger) == nil)
    }

    /// A step with a pick gets no new option too: the pick already fits.
    @Test
    func `a new option for a step that got a pick isn't offered`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter(reading: LoopReading(
            picks: [.trigger: "trigger.work"],
            newOptions: [.trigger: "Boss"],
        )))
        model.described = "My boss emailed again."

        await model.fillIn(saved: [])

        #expect(model.suggestedOption(for: .trigger) == nil)
    }

    @Test
    func `a cancelled read isn't taken for one that couldn't tell`() async {
        let interpreter = FakeLoopInterpreter()
        interpreter.error = CancellationError()
        let model = LogLoopViewModel(interpreter: interpreter)
        model.described = "Work email again."

        await model.fillIn(saved: [])

        #expect(!model.couldntTell)
        #expect(model.described == "Work email again.")
    }

    @Test
    func `editing the words clears couldn't tell`() async {
        let model = LogLoopViewModel(interpreter: FakeLoopInterpreter())
        model.described = "ugh, today"
        await model.fillIn(saved: [])

        model.described = "ugh, today. Work"

        #expect(!model.couldntTell)
    }
}
