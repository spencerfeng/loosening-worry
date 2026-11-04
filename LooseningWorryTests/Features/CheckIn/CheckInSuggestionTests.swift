@testable import LooseningWorry
import Testing

struct CheckInSuggestionTests {
    private func suggestion(_ pleasantness: Pleasantness, feelings: [Feeling]) -> CheckInSuggestion {
        CheckInSuggestion(for: CheckInAnswer(pleasantness: pleasantness, feelings: feelings))
    }

    @Test(arguments: [Pleasantness.neutral, .slightlyPleasant, .pleasant, .veryPleasant])
    func `a neutral or pleasant feeling gets no tool`(pleasantness: Pleasantness) {
        let result = suggestion(pleasantness, feelings: [.worried, .stressed])

        #expect(result.tool == nil)
    }

    /// Worry is met with curiosity, self-judgment with kindness, heat with noting, and tiredness with breath.
    @Test(arguments: [
        ([Feeling.anxious, .worried, .scared, .stressed, .overwhelmed], QuickTool.curious),
        ([.ashamed, .guilty, .embarrassed, .sad, .lonely, .hopeless, .discouraged, .disappointed], .beKind),
        ([.angry, .annoyed, .irritated, .frustrated, .jealous, .disgusted], .noteIt),
        ([.drained], .breathe),
    ])
    func `each kind of unpleasant word suggests its own tool`(feelings: [Feeling], tool: QuickTool) {
        for pleasantness in [Pleasantness.veryUnpleasant, .unpleasant, .slightlyUnpleasant] {
            for feeling in feelings {
                #expect(suggestion(pleasantness, feelings: [feeling]).tool == tool)
            }
        }
    }

    @Test(arguments: [[Feeling](), [.surprised], [.indifferent, .calm]])
    func `an unpleasant feeling with no telling word suggests Get curious`(feelings: [Feeling]) {
        #expect(suggestion(.unpleasant, feelings: feelings).tool == .curious)
    }

    @Test
    func `when words point to different tools, the one most of them point to wins`() {
        let result = suggestion(.unpleasant, feelings: [.angry, .ashamed, .guilty])

        #expect(result.tool == .beKind)
    }

    /// A tie goes to worry, then self-judgment, then heat, then tiredness, whatever order the words were picked in.
    @Test(arguments: [
        ([Feeling.annoyed, .anxious], QuickTool.curious),
        ([.drained, .sad], .beKind),
        ([.drained, .frustrated], .noteIt),
        ([.irritated, .lonely, .scared], .curious),
        ([.angry, .sad], .beKind),
    ])
    func `a tie goes to worry, then self-judgment, then heat, then tiredness`(feelings: [Feeling], tool: QuickTool) {
        #expect(suggestion(.unpleasant, feelings: feelings).tool == tool)
    }
}
