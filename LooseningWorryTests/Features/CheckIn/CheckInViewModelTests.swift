@testable import LooseningWorry
import Testing

@MainActor
struct CheckInViewModelTests {
    @Test
    func `starts by asking how it feels, and goes on only once a step is chosen`() {
        let model = CheckInViewModel()
        #expect(model.step == .pleasantness)
        #expect(model.pleasantness == nil)

        model.next()
        #expect(model.step == .pleasantness)

        model.choose(.unpleasant)
        model.next()
        #expect(model.step == .feelings)
        #expect(model.pleasantness == .unpleasant)
    }

    @Test
    func `before step 1 is answered there are no words, chips or closing line yet`() {
        let model = CheckInViewModel()

        #expect(model.groupedFeelings.first.isEmpty)
        #expect(model.groupedFeelings.more.isEmpty)
        #expect(model.summary.isEmpty)
        #expect(model.closingLine == nil)
    }

    /// The first few of each group, alphabetical; `FeelingTests` pins every word.
    @Test(arguments: [
        (Pleasantness.veryUnpleasant, [Feeling.angry, .annoyed, .anxious], [Feeling.amazed, .amused, .brave]),
        (.neutral, [.calm, .content, .drained], [.amazed, .amused, .angry]),
        (.pleasant, [.amazed, .amused, .brave], [.angry, .annoyed, .anxious]),
    ])
    func `step 2 lists the words that fit how it feels first`(
        pleasantness: Pleasantness,
        first: [Feeling],
        more: [Feeling],
    ) {
        let model = onWords(pleasantness)

        #expect(Array(model.groupedFeelings.first.prefix(3)) == first)
        #expect(Array(model.groupedFeelings.more.prefix(3)) == more)
    }

    @Test
    func `words toggle on and off and keep the order they were picked in`() {
        let model = onWords(.unpleasant)

        model.toggle(.overwhelmed)
        model.toggle(.anxious)
        model.toggle(.drained)
        #expect(model.feelings == [.overwhelmed, .anxious, .drained])

        model.toggle(.anxious)
        #expect(model.feelings == [.overwhelmed, .drained])
    }

    @Test
    func `going back to change how it feels keeps the words picked`() {
        let model = onWords(.unpleasant)
        model.toggle(.anxious)

        model.back()
        #expect(model.step == .pleasantness)
        model.choose(.slightlyUnpleasant)
        model.next()

        #expect(model.feelings == [.anxious])
        // Slightly unpleasant adds Indifferent to the unpleasant words.
        #expect(model.groupedFeelings.first.contains(.indifferent))
    }

    @Test
    func `tapping Done saves the check-in and shows what to try`() {
        let model = onWords(.unpleasant)
        model.toggle(.anxious)
        model.toggle(.overwhelmed)
        var stored: [CheckIn] = []

        model.finish { stored.append($0) }

        #expect(stored.count == 1)
        #expect(stored.first?.pleasantness == .unpleasant)
        #expect(stored.first?.feelings == [.anxious, .overwhelmed])
        #expect(model.step == .finished(CheckInSuggestion(for: CheckInAnswer(
            pleasantness: .unpleasant,
            feelings: [.anxious, .overwhelmed],
        ))))
    }

    @Test
    func `if saving fails, it stays on step 2 to try again, and saves just once`() {
        struct Failed: Error {}
        let model = onWords(.neutral)
        var stored: [CheckIn] = []

        model.finish { _ in throw Failed() }
        #expect(model.step == .feelings)
        #expect(model.saveFailed)
        #expect(model.suggestion == nil)

        model.finish { stored.append($0) }
        #expect(model.suggestion != nil)
        #expect(!model.saveFailed)
        #expect(stored.count == 1)
    }

    /// The failure note belongs to Done, so it shouldn't linger under Next.
    @Test
    func `going back after a failed save clears the failure`() {
        struct Failed: Error {}
        let model = onWords(.neutral)
        model.finish { _ in throw Failed() }

        model.back()

        #expect(!model.saveFailed)
    }

    @Test
    func `once saved, Done doesn't save again`() {
        let model = onWords(.pleasant)
        var stored: [CheckIn] = []

        model.finish { stored.append($0) }
        model.finish { stored.append($0) }

        #expect(stored.count == 1)
    }

    @Test
    func `the finish screen sums up how it felt, then each word in the order picked`() {
        let model = onWords(.veryUnpleasant)
        model.toggle(.lonely)
        model.toggle(.hopeless)

        model.finish { _ in }

        #expect(model.summary.map { String(localized: $0) } == ["Very unpleasant", "Lonely", "Hopeless"])
    }

    @Test(arguments: [
        (Pleasantness.veryUnpleasant, "Thanks for naming it. That alone gives you a little space from it."),
        (.slightlyUnpleasant, "Thanks for naming it. That alone gives you a little space from it."),
        (.neutral, "Noticing how you are, whatever it is, is the practice."),
        (.slightlyPleasant, "Noticing a good moment counts too. Your brain learns from what feels good."),
        (.veryPleasant, "Noticing a good moment counts too. Your brain learns from what feels good."),
    ])
    func `the finish screen's line fits how it felt`(pleasantness: Pleasantness, line: String) {
        let model = onWords(pleasantness)

        model.finish { _ in }

        #expect(model.closingLine.map { String(localized: $0) } == line)
    }

    /// A check-in on step 2, after `pleasantness`.
    private func onWords(_ pleasantness: Pleasantness) -> CheckInViewModel {
        let model = CheckInViewModel()
        model.choose(pleasantness)
        model.next()
        return model
    }
}
