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

        #expect(starters.map { String(localized: $0.label) } == labels)
        #expect(starters.allSatisfy { $0.kind == kind })
    }

    @Test
    func `the triggers have stable ids`() {
        #expect(StarterOption.options(for: .trigger).map(\.id) == [
            "trigger.work", "trigger.deadline", "trigger.money", "trigger.health", "trigger.familyOrPartner",
            "trigger.socialPlans", "trigger.news", "trigger.waitingForReply", "trigger.tryingToSleep",
            "trigger.outOfNowhere",
        ])
    }

    @Test
    func `the behaviors have stable ids`() {
        #expect(StarterOption.options(for: .behavior).map(\.id) == [
            "behavior.overthought", "behavior.keptChecking", "behavior.askedForReassurance",
            "behavior.searchedOnline", "behavior.avoidedIt", "behavior.putItOff", "behavior.overPrepared",
            "behavior.scrolled", "behavior.snacked",
        ])
    }

    @Test
    func `the core results have stable ids, worse to better, then not sure`() {
        #expect(StarterOption.options(for: .result).map(\.id) == [
            "result.moreWorry", "result.tenseAndTired", "result.nothingChanged", "result.littleRelief",
            "result.actuallyHelped", "result.notSure",
        ])
    }

    /// Overrides find their starter by id, so two starters must never share one.
    @Test
    func `every starter has its own id`() {
        let ids = StarterOption.all.map(\.id)

        #expect(Set(ids).count == ids.count)
    }

    @Test
    func `a starter can be found by its id`() throws {
        let news = try #require(StarterOption.with(id: "trigger.news"))

        #expect(news.kind == .trigger)
        #expect(news.label.key == "starter.trigger.news")
        #expect(StarterOption.with(id: "trigger.unknown") == nil)
    }

    /// The catalog key is spelled out for string extraction, so it could drift from the id.
    @Test
    func `every starter's catalog key matches its id`() {
        for starter in StarterOption.all {
            #expect(starter.label.key == "starter.\(starter.id)")
        }
    }
}
