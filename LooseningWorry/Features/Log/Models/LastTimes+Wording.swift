import Foundation

/// The card's words. Each starter gets whole sentences of its own, so a translator can word the habit and the result
/// the way their language needs; anything in the person's words follows the sentence as it was logged. "times" is a
/// plural, written by hand in the catalog.
extension LastTimes {
    /// "The last 5 times you overthought it", or "The last 5 times: I doomscrolled".
    var title: LocalizedStringResource {
        let count = total
        switch habit {
        case .starter(.overthought):
            return LocalizedStringResource(
                "niceCatch.lastTimes.overthought",
                defaultValue: "The last \(count) times you overthought it",
            )
        case .starter(.keptChecking):
            return LocalizedStringResource(
                "niceCatch.lastTimes.keptChecking",
                defaultValue: "The last \(count) times you kept checking",
            )
        case .starter(.askedForReassurance):
            return LocalizedStringResource(
                "niceCatch.lastTimes.askedForReassurance",
                defaultValue: "The last \(count) times you asked for reassurance",
            )
        case .starter(.searchedOnline):
            return LocalizedStringResource(
                "niceCatch.lastTimes.searchedOnline",
                defaultValue: "The last \(count) times you searched online",
            )
        case .starter(.avoidedIt):
            return LocalizedStringResource(
                "niceCatch.lastTimes.avoidedIt",
                defaultValue: "The last \(count) times you avoided it",
            )
        case .starter(.putItOff):
            return LocalizedStringResource(
                "niceCatch.lastTimes.putItOff",
                defaultValue: "The last \(count) times you put it off",
            )
        case .starter(.overPrepared):
            return LocalizedStringResource(
                "niceCatch.lastTimes.overPrepared",
                defaultValue: "The last \(count) times you over-prepared",
            )
        case .starter(.scrolled):
            return LocalizedStringResource(
                "niceCatch.lastTimes.scrolled",
                defaultValue: "The last \(count) times you scrolled",
            )
        case .starter(.snacked):
            return LocalizedStringResource(
                "niceCatch.lastTimes.snacked",
                defaultValue: "The last \(count) times you snacked",
            )
        default:
            return LocalizedStringResource(
                "niceCatch.lastTimes.own",
                defaultValue: "The last \(count) times: \(habit.text)",
            )
        }
    }

    /// "**4 of 5 times** it gave you more worry.", with the count in bold for the card to restyle; "4 of 5 times"
    /// keeps together on one line.
    var line: AttributedString {
        let (count, total) = (topResult.count, total)
        let line = switch topResult.result {
        case .starter(.moreWorry):
            LocalizedStringResource(
                "niceCatch.lastTimes.moreWorry",
                defaultValue: "**\(count)\u{00A0}of\u{00A0}\(total)\u{00A0}times** it gave you more worry.",
            )
        case .starter(.tenseAndTired):
            LocalizedStringResource(
                "niceCatch.lastTimes.tenseAndTired",
                defaultValue: "**\(count)\u{00A0}of\u{00A0}\(total)\u{00A0}times** it left you tense and tired.",
            )
        case .starter(.nothingChanged):
            LocalizedStringResource(
                "niceCatch.lastTimes.nothingChanged",
                defaultValue: "**\(count)\u{00A0}of\u{00A0}\(total)\u{00A0}times** nothing changed.",
            )
        case .starter(.littleRelief):
            LocalizedStringResource(
                "niceCatch.lastTimes.littleRelief",
                defaultValue: "**\(count)\u{00A0}of\u{00A0}\(total)\u{00A0}times** it gave you a little relief.",
            )
        case .starter(.actuallyHelped):
            LocalizedStringResource(
                "niceCatch.lastTimes.actuallyHelped",
                defaultValue: "**\(count)\u{00A0}of\u{00A0}\(total)\u{00A0}times** it actually helped.",
            )
        case .starter(.notSure):
            LocalizedStringResource(
                "niceCatch.lastTimes.notSure",
                defaultValue: "**\(count)\u{00A0}of\u{00A0}\(total)\u{00A0}times** you weren't sure what it gave you.",
            )
        default:
            LocalizedStringResource(
                "niceCatch.lastTimes.ownResult",
                defaultValue: "**\(count)\u{00A0}of\u{00A0}\(total)\u{00A0}times**: \(topResult.result.text)",
            )
        }
        return AttributedString(localized: line)
    }
}
