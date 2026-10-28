import Foundation

/// Be kind's pages: the self-compassion break (Neff and Germer's Mindful Self-Compassion), noticing how you're talking
/// to yourself, a kind touch, then that it's hard, that others feel this too, and kindness; then what you'd say to a
/// friend, and something to take away. Invitations, never instructions: every page can be passed by. The wording is
/// Claude's draft from that practice and clinical writing; worth a clinician's review before launch.
enum KindPage: CaseIterable {
    case notice, touch, hard, notAlone, kindness, friend, takeAway

    /// The wordings a phrase page offers, plainest first; the other pages have none.
    var wordings: [KindWording] {
        switch self {
        case .hard: [.thisIsHard, .momentOfStruggle, .makesSense]
        case .notAlone: [.lotsOfPeople, .notAloneInThis, .partOfBeingHuman]
        case .kindness: [.mayIBeKind, .gentleWithMyself, .doingMyBest]
        case .notice, .touch, .friend, .takeAway: []
        }
    }

    /// What a page that isn't a phrase says.
    var title: LocalizedStringResource {
        switch self {
        case .notice:
            LocalizedStringResource(
                "tool.beKind.notice",
                defaultValue: "Notice how you're talking to yourself right now.",
            )
        case .touch:
            LocalizedStringResource("tool.beKind.touch", defaultValue: "If it feels okay, rest a hand on your chest.")
        case .friend:
            LocalizedStringResource(
                "tool.beKind.friend",
                defaultValue: "What would you say to a friend who felt this way?",
            )
        case .takeAway:
            LocalizedStringResource("tool.beKind.takeAway", defaultValue: "Something to take with you")
        case .hard, .notAlone, .kindness:
            wordings[0].text
        }
    }

    /// The quieter line under the page's phrase or question.
    var guide: LocalizedStringResource {
        switch self {
        case .notice:
            LocalizedStringResource(
                "tool.beKind.notice.guide",
                defaultValue: "Is the voice harsh, or kind? Just notice. You don't need to change it.",
            )
        case .touch:
            LocalizedStringResource(
                "tool.beKind.touch.guide",
                defaultValue: "Or anywhere that feels soothing. Feel its warmth for a breath or two.",
            )
        case .hard:
            LocalizedStringResource(
                "tool.beKind.hard.guide",
                defaultValue: "Read it slowly, and let it land with one breath.",
            )
        case .notAlone:
            LocalizedStringResource(
                "tool.beKind.notAlone.guide",
                defaultValue: "Right now, others are feeling something like this too.",
            )
        case .kindness:
            LocalizedStringResource(
                "tool.beKind.kindness.guide",
                defaultValue: "If this feels awkward or untrue, that's common. Kindness gets easier with practice.",
            )
        case .friend:
            LocalizedStringResource(
                "tool.beKind.friend.guide",
                defaultValue: "Write it if you like. Then say it to yourself, the same way.",
            )
        case .takeAway:
            LocalizedStringResource(
                "tool.beKind.takeAway.guide",
                defaultValue: "Come back to it whenever the harsh voice returns.",
            )
        }
    }
}

/// One way of saying a phrase, by a stable id; its words are translated.
enum KindWording: String, CaseIterable {
    case thisIsHard, momentOfStruggle, makesSense
    case lotsOfPeople, notAloneInThis, partOfBeingHuman
    case mayIBeKind, gentleWithMyself, doingMyBest

    var id: Self {
        self
    }

    var text: LocalizedStringResource {
        switch self {
        case .thisIsHard: LocalizedStringResource("tool.beKind.thisIsHard", defaultValue: "This is hard right now.")
        case .momentOfStruggle:
            LocalizedStringResource("tool.beKind.momentOfStruggle", defaultValue: "This is a moment of struggle.")
        case .makesSense:
            LocalizedStringResource("tool.beKind.makesSense", defaultValue: "It makes sense that this feels hard.")
        case .lotsOfPeople: LocalizedStringResource(
                "tool.beKind.lotsOfPeople",
                defaultValue: "Lots of people feel this way.",
            )
        case .notAloneInThis: LocalizedStringResource(
                "tool.beKind.notAloneInThis",
                defaultValue: "I'm not alone in this.",
            )
        case .partOfBeingHuman:
            LocalizedStringResource(
                "tool.beKind.partOfBeingHuman",
                defaultValue: "Struggling like this is part of being human.",
            )
        case .mayIBeKind:
            LocalizedStringResource("tool.beKind.mayIBeKind", defaultValue: "May I be kind to myself right now.")
        case .gentleWithMyself:
            LocalizedStringResource("tool.beKind.gentleWithMyself", defaultValue: "I can be gentle with myself.")
        case .doingMyBest:
            LocalizedStringResource(
                "tool.beKind.doingMyBest",
                defaultValue: "I'm doing the best I can with what I have.",
            )
        }
    }
}
