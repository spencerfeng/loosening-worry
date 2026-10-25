import Foundation
@testable import LooseningWorry
import Testing

struct StarterOptionTests {
    @Test(arguments: [
        (OptionKind.trigger, [
            "Work", "Deadline", "Money", "Health", "Family or partner", "Social plans", "News", "Waiting for a reply",
            "Trying to sleep", "Out of nowhere",
        ]),
        (OptionKind.behavior, [
            "Overthought it", "Kept checking", "Asked for reassurance", "Searched online", "Avoided it", "Put it off",
            "Over-prepared", "Scrolled", "Snacked",
        ]),
        (OptionKind.result, [
            "More worry", "Tense and tired", "Nothing changed", "A little relief", "It actually helped", "Not sure",
        ]),
    ])
    func `each kind offers its starters in order`(kind: OptionKind, labels: [String]) {
        let starters = StarterOption.options(for: kind)

        #expect(starters.map(\.text) == labels)
        #expect(starters.allSatisfy { $0.kind == kind })
    }

    @Test
    func `the triggers have stable ids`() {
        #expect(StarterOption.options(for: .trigger).map(\.id.rawValue) == [
            "trigger.work", "trigger.deadline", "trigger.money", "trigger.health", "trigger.familyOrPartner",
            "trigger.socialPlans", "trigger.news", "trigger.waitingForReply", "trigger.tryingToSleep",
            "trigger.outOfNowhere",
        ])
    }

    @Test
    func `the behaviors have stable ids`() {
        #expect(StarterOption.options(for: .behavior).map(\.id.rawValue) == [
            "behavior.overthought", "behavior.keptChecking", "behavior.askedForReassurance",
            "behavior.searchedOnline", "behavior.avoidedIt", "behavior.putItOff", "behavior.overPrepared",
            "behavior.scrolled", "behavior.snacked",
        ])
    }

    @Test
    func `the core results have stable ids, worse to better, then not sure`() {
        #expect(StarterOption.options(for: .result).map(\.id.rawValue) == [
            "result.moreWorry", "result.tenseAndTired", "result.nothingChanged", "result.littleRelief",
            "result.actuallyHelped", "result.notSure",
        ])
    }

    /// A starter's kind is read from its id, so a mistyped prefix would put it on the wrong step.
    @Test(arguments: StarterID.allCases)
    func `every id starts with its kind`(id: StarterID) {
        #expect(id.rawValue.wholeMatch(of: /(trigger|behavior|result)\.[a-zA-Z]+/) != nil)
        #expect(StarterOption.options(for: id.kind).contains { $0.id == id })
    }

    @Test
    func `a starter can be found by its id`() {
        let news = StarterOption.with(id: .news)

        #expect(news.kind == .trigger)
        #expect(news.label.key == "starter.trigger.news")
    }

    /// The catalog key is spelled out for string extraction, so it could drift from the id.
    @Test
    func `every starter's catalog key matches its id`() {
        for starter in StarterOption.all {
            #expect(starter.label.key == "starter.\(starter.id.rawValue)")
        }
    }
}
