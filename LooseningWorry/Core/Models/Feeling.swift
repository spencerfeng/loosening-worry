import Foundation

/// One of the check-in's words for a feeling. The list is fixed, one for each of HealthKit's State of Mind labels,
/// and the person can't add to it, hide or reword it.
///
/// The raw value is what a check-in stores, so it never changes once released.
enum Feeling: String, CaseIterable, Sendable {
    case amazed = "feeling.amazed"
    case amused = "feeling.amused"
    case angry = "feeling.angry"
    case annoyed = "feeling.annoyed"
    case anxious = "feeling.anxious"
    case ashamed = "feeling.ashamed"
    case brave = "feeling.brave"
    case calm = "feeling.calm"
    case confident = "feeling.confident"
    case content = "feeling.content"
    case disappointed = "feeling.disappointed"
    case discouraged = "feeling.discouraged"
    case disgusted = "feeling.disgusted"
    case drained = "feeling.drained"
    case embarrassed = "feeling.embarrassed"
    case excited = "feeling.excited"
    case frustrated = "feeling.frustrated"
    case grateful = "feeling.grateful"
    case guilty = "feeling.guilty"
    case happy = "feeling.happy"
    case hopeful = "feeling.hopeful"
    case hopeless = "feeling.hopeless"
    case indifferent = "feeling.indifferent"
    case irritated = "feeling.irritated"
    case jealous = "feeling.jealous"
    case joyful = "feeling.joyful"
    case lonely = "feeling.lonely"
    case overwhelmed = "feeling.overwhelmed"
    case passionate = "feeling.passionate"
    case peaceful = "feeling.peaceful"
    case proud = "feeling.proud"
    case relieved = "feeling.relieved"
    case sad = "feeling.sad"
    case satisfied = "feeling.satisfied"
    case scared = "feeling.scared"
    case stressed = "feeling.stressed"
    case surprised = "feeling.surprised"
    case worried = "feeling.worried"

    /// The words for step 2 after `pleasantness` in step 1: those that fit it first, the rest under More, each
    /// alphabetical as shown.
    static func grouped(for pleasantness: Pleasantness) -> (first: [Feeling], more: [Feeling]) {
        let fitting: Set<Feeling> = switch pleasantness {
        case .veryUnpleasant, .unpleasant: unpleasant
        case .slightlyUnpleasant: unpleasant.union([.indifferent])
        case .neutral: neutral
        case .slightlyPleasant: pleasant.union([.indifferent])
        case .pleasant, .veryPleasant: pleasant
        }
        let shown = allCases.sorted {
            String(localized: $0.label).localizedStandardCompare(String(localized: $1.label)) == .orderedAscending
        }
        return (shown.filter(fitting.contains), shown.filter { !fitting.contains($0) })
    }

    private static let unpleasant: Set<Feeling> = [
        .angry, .annoyed, .anxious, .ashamed, .disappointed, .discouraged, .disgusted, .drained, .embarrassed,
        .frustrated, .guilty, .hopeless, .irritated, .jealous, .lonely, .overwhelmed, .sad, .scared, .stressed,
        .surprised, .worried,
    ]

    private static let pleasant: Set<Feeling> = [
        .amazed, .amused, .brave, .calm, .confident, .content, .excited, .grateful, .happy, .hopeful, .joyful,
        .passionate, .peaceful, .proud, .relieved, .satisfied, .surprised,
    ]

    /// Our own pick: Apple's grouping for neutral isn't published. Calm and settled words, plus the low-key
    /// unpleasant ones someone might call neutral.
    private static let neutral: Set<Feeling> = [
        .calm, .content, .drained, .indifferent, .peaceful, .relieved, .satisfied, .stressed, .surprised, .worried,
    ]

    /// The word as the check-in shows it, translated. The catalog key is spelled out so the compiler can extract it.
    var label: LocalizedStringResource {
        switch self {
        case .amazed: LocalizedStringResource("feeling.amazed", defaultValue: "Amazed")
        case .amused: LocalizedStringResource("feeling.amused", defaultValue: "Amused")
        case .angry: LocalizedStringResource("feeling.angry", defaultValue: "Angry")
        case .annoyed: LocalizedStringResource("feeling.annoyed", defaultValue: "Annoyed")
        case .anxious: LocalizedStringResource("feeling.anxious", defaultValue: "Anxious")
        case .ashamed: LocalizedStringResource("feeling.ashamed", defaultValue: "Ashamed")
        case .brave: LocalizedStringResource("feeling.brave", defaultValue: "Brave")
        case .calm: LocalizedStringResource("feeling.calm", defaultValue: "Calm")
        case .confident: LocalizedStringResource("feeling.confident", defaultValue: "Confident")
        case .content: LocalizedStringResource("feeling.content", defaultValue: "Content")
        case .disappointed: LocalizedStringResource("feeling.disappointed", defaultValue: "Disappointed")
        case .discouraged: LocalizedStringResource("feeling.discouraged", defaultValue: "Discouraged")
        case .disgusted: LocalizedStringResource("feeling.disgusted", defaultValue: "Disgusted")
        case .drained: LocalizedStringResource("feeling.drained", defaultValue: "Drained")
        case .embarrassed: LocalizedStringResource("feeling.embarrassed", defaultValue: "Embarrassed")
        case .excited: LocalizedStringResource("feeling.excited", defaultValue: "Excited")
        case .frustrated: LocalizedStringResource("feeling.frustrated", defaultValue: "Frustrated")
        case .grateful: LocalizedStringResource("feeling.grateful", defaultValue: "Grateful")
        case .guilty: LocalizedStringResource("feeling.guilty", defaultValue: "Guilty")
        case .happy: LocalizedStringResource("feeling.happy", defaultValue: "Happy")
        case .hopeful: LocalizedStringResource("feeling.hopeful", defaultValue: "Hopeful")
        case .hopeless: LocalizedStringResource("feeling.hopeless", defaultValue: "Hopeless")
        case .indifferent: LocalizedStringResource("feeling.indifferent", defaultValue: "Indifferent")
        case .irritated: LocalizedStringResource("feeling.irritated", defaultValue: "Irritated")
        case .jealous: LocalizedStringResource("feeling.jealous", defaultValue: "Jealous")
        case .joyful: LocalizedStringResource("feeling.joyful", defaultValue: "Joyful")
        case .lonely: LocalizedStringResource("feeling.lonely", defaultValue: "Lonely")
        case .overwhelmed: LocalizedStringResource("feeling.overwhelmed", defaultValue: "Overwhelmed")
        case .passionate: LocalizedStringResource("feeling.passionate", defaultValue: "Passionate")
        case .peaceful: LocalizedStringResource("feeling.peaceful", defaultValue: "Peaceful")
        case .proud: LocalizedStringResource("feeling.proud", defaultValue: "Proud")
        case .relieved: LocalizedStringResource("feeling.relieved", defaultValue: "Relieved")
        case .sad: LocalizedStringResource("feeling.sad", defaultValue: "Sad")
        case .satisfied: LocalizedStringResource("feeling.satisfied", defaultValue: "Satisfied")
        case .scared: LocalizedStringResource("feeling.scared", defaultValue: "Scared")
        case .stressed: LocalizedStringResource("feeling.stressed", defaultValue: "Stressed")
        case .surprised: LocalizedStringResource("feeling.surprised", defaultValue: "Surprised")
        case .worried: LocalizedStringResource("feeling.worried", defaultValue: "Worried")
        }
    }
}
