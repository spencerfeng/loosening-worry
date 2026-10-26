import Foundation
@testable import LooseningWorry
import Testing

@MainActor
struct LogLoopOrderTests {
    let pairs: StarterPairs

    init() throws {
        pairs = try StarterPairs(json: Data(#"{"trigger.news": ["behavior.scrolled", "behavior.keptChecking"]}"#.utf8))
    }

    private func model(loops: [Loop] = []) -> LogLoopViewModel {
        let model = LogLoopViewModel(pairs: pairs)
        model.recentLoops = loops
        return model
    }

    private func loop(_ trigger: StarterID, _ behavior: StarterID) -> Loop {
        .sample(trigger: OptionChoice(trigger, label: ""), behavior: OptionChoice(behavior, label: ""))
    }

    @Test
    func `step 1 puts the person's most logged triggers first`() {
        let model = model(loops: [loop(.money, .snacked), loop(.money, .snacked)])

        #expect(model.choices(for: .trigger, saved: []).first?.starterID == .money)
    }

    /// The order is worked out from the trigger picked, so changing the trigger changes it.
    @Test
    func `step 2 follows the trigger picked, and changes with it`() {
        let model = model()

        model.pick(.news)
        #expect(model.choices(for: .behavior, saved: []).first?.starterID == .scrolled)

        model.goTo(.trigger)
        model.pick(.deadline)
        #expect(model.choices(for: .behavior, saved: []).first?.starterID == StarterOption.options(for: .behavior)[0]
            .id)
    }

    @Test
    func `step 3 keeps its fixed order, whatever the history`() {
        let many = Array(repeating: Loop.sample(result: OptionChoice(.notSure, label: "")), count: 5)
        let model = model(loops: many)

        let results = model.choices(for: .result, saved: []).compactMap(\.starterID)

        #expect(results == StarterOption.options(for: .result).map(\.id))
    }

    // MARK: - More

    @Test
    func `steps 1 and 2 show six choices and More, until the person asks for the rest`() {
        let model = model()
        let all = model.choices(for: .trigger, saved: [])

        let shown = model.visibleChoices(all, for: .trigger)
        #expect(shown.choices == Array(all.prefix(6)))
        #expect(shown.hasMore)

        model.showAllChoices()

        let expanded = model.visibleChoices(all, for: .trigger)
        #expect(expanded.choices == all)
        #expect(expanded.hasMore == false)
    }

    @Test
    func `step 3 shows every result, with no More`() {
        let model = model()
        model.pick(.news)
        model.pick(.scrolled)
        let all = model.choices(for: .result, saved: [])

        let shown = model.visibleChoices(all, for: .result)

        #expect(shown.choices == all)
        #expect(shown.hasMore == false)
    }

    /// Reopening a step whose answer sits behind More shows the whole list, so the answer is in view.
    @Test
    func `a reopened step whose answer is past the first six shows them all`() throws {
        let model = model()
        let all = model.choices(for: .trigger, saved: [])
        let seventh = try #require(all.dropFirst(6).first)
        model.pick(seventh)

        model.goTo(.trigger)

        #expect(model.visibleChoices(all, for: .trigger).choices == all)
    }

    @Test
    func `the next step starts with six again`() {
        let model = model()
        model.showAllChoices()

        model.pick(.news)

        let behaviors = model.choices(for: .behavior, saved: [])
        #expect(model.visibleChoices(behaviors, for: .behavior).choices.count == 6)
    }

    /// The order is worked out when the step opens; an option synced in meanwhile joins at the end.
    @Test
    func `the order holds while a step is showing`() {
        let model = model(loops: [loop(.money, .snacked)])
        let before = model.choices(for: .trigger, saved: [])
        let synced = LoopOption(kind: .trigger, label: "Rent due")

        let after = model.choices(for: .trigger, saved: [synced])

        #expect(Array(after.dropLast()) == before)
        #expect(after.last?.label == "Rent due")
    }

    @Test
    func `the order is worked out again when the step opens again`() {
        let model = model()
        _ = model.choices(for: .trigger, saved: [])
        model.pick(.news)
        let synced = LoopOption(kind: .trigger, label: "Rent due")

        model.goTo(.trigger)

        #expect(model.choices(for: .trigger, saved: [synced]).first?.label == "Rent due")
    }

    @Test
    func `the full list on step 2 shows every behavior the person hasn't hidden, in ranked order`() {
        let hidden = LoopOption(overriding: .snacked, label: "Snacked")
        hidden.isHidden = true
        let model = model()
        model.pick(.news)
        let all = model.choices(for: .behavior, saved: [hidden])

        model.showAllChoices()

        let shown = model.visibleChoices(all, for: .behavior).choices
        #expect(shown == all)
        #expect(Array(shown.prefix(2)).compactMap(\.starterID) == [.scrolled, .keptChecking])
        #expect(!shown.contains { $0.starterID == .snacked })
        #expect(shown.count == StarterOption.options(for: .behavior).count - 1)
    }

    /// An answer can come to show under another choice, when a copy synced in took its text; it's still the answer.
    @Test
    func `a choice showing the answer under a merged id counts as the answer`() throws {
        let model = model()
        model.pick(.news)
        model.goTo(.trigger)
        let copy = LoopOption(kind: .trigger, label: "News")

        let choices = model.choices(for: .trigger, saved: [copy])

        let news = try #require(choices.first { $0.label == "News" })
        #expect(news.id == copy.optionID)
        #expect(model.answerID(in: choices, for: .trigger) == copy.optionID)
    }

    /// Back from Edit options, the step keeps its order: a removed option leaves, and a new one joins the end.
    @Test
    func `after editing options, removed ones leave the step and new ones join the end`() {
        let model = model()
        let before = model.choices(for: .trigger, saved: [])
        let removed = LoopOption(overriding: .work, label: "Work")
        removed.isHidden = true
        let added = LoopOption(kind: .trigger, label: "Rent due")

        let after = model.choices(for: .trigger, saved: [removed, added])

        #expect(after.map(\.label) == before.filter { $0.starterID != .work }.map(\.label) + ["Rent due"])
    }
}
