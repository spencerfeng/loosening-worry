import Foundation
@testable import LooseningWorry
import Testing

struct FeelingTests {
    /// A check-in stores these ids, so none may change once released.
    @Test
    func `the check-in offers 38 fixed words with stable ids`() {
        #expect(Feeling.allCases.map(\.rawValue) == [
            "feeling.amazed", "feeling.amused", "feeling.angry", "feeling.annoyed", "feeling.anxious",
            "feeling.ashamed", "feeling.brave", "feeling.calm", "feeling.confident", "feeling.content",
            "feeling.disappointed", "feeling.discouraged", "feeling.disgusted", "feeling.drained",
            "feeling.embarrassed", "feeling.excited", "feeling.frustrated", "feeling.grateful", "feeling.guilty",
            "feeling.happy", "feeling.hopeful", "feeling.hopeless", "feeling.indifferent", "feeling.irritated",
            "feeling.jealous", "feeling.joyful", "feeling.lonely", "feeling.overwhelmed", "feeling.passionate",
            "feeling.peaceful", "feeling.proud", "feeling.relieved", "feeling.sad", "feeling.satisfied",
            "feeling.scared", "feeling.stressed", "feeling.surprised", "feeling.worried",
        ])
    }

    @Test
    func `each word shows its own label`() {
        #expect(Feeling.allCases.map { String(localized: $0.label) } == [
            "Amazed", "Amused", "Angry", "Annoyed", "Anxious", "Ashamed", "Brave", "Calm", "Confident", "Content",
            "Disappointed", "Discouraged", "Disgusted", "Drained", "Embarrassed", "Excited", "Frustrated", "Grateful",
            "Guilty", "Happy", "Hopeful", "Hopeless", "Indifferent", "Irritated", "Jealous", "Joyful", "Lonely",
            "Overwhelmed", "Passionate", "Peaceful", "Proud", "Relieved", "Sad", "Satisfied", "Scared", "Stressed",
            "Surprised", "Worried",
        ])
    }

    /// The order the Apple Watch's State of Mind log shows after very unpleasant.
    @Test
    func `very unpleasant puts every pleasant word, and indifferent, under More`() {
        #expect(Feeling.grouped(for: .veryUnpleasant).more.map { String(localized: $0.label) } == [
            "Amazed", "Amused", "Brave", "Calm", "Confident", "Content", "Excited", "Grateful", "Happy", "Hopeful",
            "Indifferent", "Joyful", "Passionate", "Peaceful", "Proud", "Relieved", "Satisfied",
        ])
    }

    private static let unpleasantWords = [
        "Angry", "Annoyed", "Anxious", "Ashamed", "Disappointed", "Discouraged", "Disgusted", "Drained", "Embarrassed",
        "Frustrated", "Guilty", "Hopeless", "Irritated", "Jealous", "Lonely", "Overwhelmed", "Sad", "Scared",
        "Stressed", "Surprised", "Worried",
    ]
    private static let pleasantWords = [
        "Amazed", "Amused", "Brave", "Calm", "Confident", "Content", "Excited", "Grateful", "Happy", "Hopeful",
        "Joyful", "Passionate", "Peaceful", "Proud", "Relieved", "Satisfied", "Surprised",
    ]

    /// Indifferent sits between the two sides, so the slightly steps offer it too.
    @Test(arguments: [
        (Pleasantness.veryUnpleasant, unpleasantWords),
        (.unpleasant, unpleasantWords),
        (.slightlyUnpleasant, (unpleasantWords + ["Indifferent"]).sorted()),
        (.neutral, [
            "Calm", "Content", "Drained", "Indifferent", "Peaceful", "Relieved", "Satisfied", "Stressed", "Surprised",
            "Worried",
        ]),
        (.slightlyPleasant, (pleasantWords + ["Indifferent"]).sorted()),
        (.pleasant, pleasantWords),
        (.veryPleasant, pleasantWords),
    ])
    func `each step lists the words that fit it first`(pleasantness: Pleasantness, first: [String]) {
        let words = Feeling.grouped(for: pleasantness)

        #expect(words.first.map { String(localized: $0.label) } == first)
        #expect(Set(words.first + words.more) == Set(Feeling.allCases))
        #expect(words.first.count + words.more.count == Feeling.allCases.count)
    }
}
