import Foundation
@testable import LooseningWorry
import Testing

struct OptionListTests {
    @Test(arguments: [OptionKind.trigger, .behavior, .result])
    func `with nothing saved, a kind offers its starters in order`(kind: OptionKind) {
        let choices = OptionList.choices(for: kind, saved: [])

        let starters = StarterOption.options(for: kind)
        #expect(choices.map(\.label) == starters.map { String(localized: $0.label) })
        #expect(choices.map(\.starterID) == starters.map(\.id))
    }

    @Test
    func `custom options come before the starters, newest first`() {
        let older = LoopOption(kind: .trigger, label: "Call from Mom")
        older.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        let newer = LoopOption(kind: .trigger, label: "Rent due")
        newer.createdAt = Date(timeIntervalSince1970: 1_800_100_000)

        let choices = OptionList.choices(for: .trigger, saved: [older, newer])

        #expect(Array(choices.prefix(2)) == [
            OptionChoice(label: "Rent due", starterID: nil),
            OptionChoice(label: "Call from Mom", starterID: nil),
        ])
        #expect(choices.dropFirst(2).map(\.starterID) == StarterOption.options(for: .trigger).map(\.id))
    }

    @Test
    func `a renamed starter shows its new text in the starter's place`() {
        let rename = LoopOption(kind: .trigger, label: "World news", starterID: "trigger.news")

        let choices = OptionList.choices(for: .trigger, saved: [rename])

        let expected = StarterOption.options(for: .trigger).map { starter in
            OptionChoice(
                label: starter.id == "trigger.news" ? "World news" : String(localized: starter.label),
                starterID: starter.id,
            )
        }
        #expect(choices == expected)
    }

    @Test
    func `hidden starters and hidden custom options are left out`() {
        let hiddenStarter = LoopOption(kind: .trigger, label: "", starterID: "trigger.news")
        hiddenStarter.isHidden = true
        let hiddenCustom = LoopOption(kind: .trigger, label: "Rent due")
        hiddenCustom.isHidden = true

        let choices = OptionList.choices(for: .trigger, saved: [hiddenStarter, hiddenCustom])

        #expect(!choices.contains { $0.starterID == "trigger.news" })
        #expect(!choices.contains { $0.label == "Rent due" })
        #expect(choices.count == StarterOption.options(for: .trigger).count - 1)
    }

    /// Two devices can each save a change to the same starter before they sync.
    @Test
    func `of two changes to the same starter, the one edited last wins, whenever it was created`() {
        let editedLast = LoopOption(kind: .trigger, label: "Headlines", starterID: "trigger.news")
        editedLast.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        editedLast.updatedAt = Date(timeIntervalSince1970: 1_800_200_000)
        let createdLast = LoopOption(kind: .trigger, label: "World news", starterID: "trigger.news")
        createdLast.createdAt = Date(timeIntervalSince1970: 1_800_100_000)
        createdLast.updatedAt = Date(timeIntervalSince1970: 1_800_100_000)

        let choices = OptionList.choices(for: .trigger, saved: [editedLast, createdLast])

        #expect(choices.filter { $0.starterID == "trigger.news" } == [
            OptionChoice(label: "Headlines", starterID: "trigger.news")
        ])
    }

    /// Fetch order differs between devices, so a tie must not fall to whichever comes first.
    @Test
    func `when two changes to a starter were edited at the same time, the one created last wins`() {
        let editedAt = Date(timeIntervalSince1970: 1_800_200_000)
        let createdFirst = LoopOption(kind: .trigger, label: "World news", starterID: "trigger.news")
        createdFirst.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        createdFirst.updatedAt = editedAt
        let createdLast = LoopOption(kind: .trigger, label: "Headlines", starterID: "trigger.news")
        createdLast.createdAt = Date(timeIntervalSince1970: 1_800_100_000)
        createdLast.updatedAt = editedAt

        for saved in [[createdFirst, createdLast], [createdLast, createdFirst]] {
            let choices = OptionList.choices(for: .trigger, saved: saved)

            #expect(choices.filter { $0.starterID == "trigger.news" } == [
                OptionChoice(label: "Headlines", starterID: "trigger.news")
            ])
        }
    }

    @Test
    func `a custom option with a starter's text appears once, with the custom options`() throws {
        let news = try #require(StarterOption.with(id: "trigger.news"))
        let label = String(localized: news.label)
        let custom = LoopOption(kind: .trigger, label: label)

        let choices = OptionList.choices(for: .trigger, saved: [custom])

        #expect(choices.first == OptionChoice(label: label, starterID: nil))
        #expect(choices.count { $0.label == label } == 1)
    }

    @Test
    func `a custom option matching a starter only in another case appears alongside it`() throws {
        let news = try #require(StarterOption.with(id: "trigger.news"))
        let typed = String(localized: news.label).lowercased()
        let custom = LoopOption(kind: .trigger, label: typed)

        let choices = OptionList.choices(for: .trigger, saved: [custom])

        #expect(choices.first == OptionChoice(label: typed, starterID: nil))
        #expect(choices.contains { $0.starterID == "trigger.news" })
    }

    @Test
    func `only options of the requested kind appear`() {
        let behavior = LoopOption(kind: .behavior, label: "Paced around")

        let choices = OptionList.choices(for: .trigger, saved: [behavior])

        #expect(choices.map(\.starterID) == StarterOption.options(for: .trigger).map(\.id))
    }
}
