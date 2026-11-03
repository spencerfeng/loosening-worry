/// What the check-in's finish screen offers after the person has named how they feel.
struct CheckInSuggestion: Equatable {
    /// The tool to try, or `nil` when there's nothing to ease.
    let tool: QuickTool?
    /// Whether to point to Help as well.
    let showsHelp: Bool

    init(for answer: CheckInAnswer) {
        tool = answer.pleasantness.isUnpleasant ? Self.tool(for: answer.feelings) : nil
        showsHelp = answer.pleasantness == .veryUnpleasant
    }

    /// The tool most of the words point to. Curiosity suits any unpleasant feeling, so it stands in when no word
    /// points anywhere.
    private static func tool(for feelings: [Feeling]) -> QuickTool {
        let votes = Dictionary(feelings.compactMap { tools[$0] }.map { ($0, 1) }, uniquingKeysWith: +)
        guard !votes.isEmpty else { return .curious }
        // `max` keeps the first of equals, so walking in priority order settles a tie.
        return tieOrder.max { votes[$0, default: 0] < votes[$1, default: 0] } ?? .curious
    }

    /// Worry first, as it's what the app is for; then self-judgment, heat and tiredness.
    private static let tieOrder: [QuickTool] = [.curious, .beKind, .noteIt, .breathe]

    /// Worry is met with curiosity, self-judgment with kindness, heat with noting, and tiredness with breath.
    private static let tools: [Feeling: QuickTool] = [
        .anxious: .curious, .worried: .curious, .scared: .curious, .stressed: .curious, .overwhelmed: .curious,
        .ashamed: .beKind, .guilty: .beKind, .embarrassed: .beKind, .sad: .beKind, .lonely: .beKind,
        .hopeless: .beKind, .discouraged: .beKind, .disappointed: .beKind,
        .angry: .noteIt, .annoyed: .noteIt, .irritated: .noteIt, .frustrated: .noteIt, .jealous: .noteIt,
        .disgusted: .noteIt,
        .drained: .breathe,
    ]
}
