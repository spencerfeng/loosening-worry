import Foundation
@testable import LooseningWorry
import Testing

struct OptionListTests {
    @Test(arguments: [OptionKind.trigger, .behavior, .result])
    func `with nothing saved, a kind offers its starters in order`(kind: OptionKind) {
        let choices = OptionList.choices(for: kind, saved: [])

        let starters = StarterOption.options(for: kind)
        #expect(choices.map(\.label) == starters.map(\.text))
        #expect(choices.map(\.starterID) == starters.map(\.id))
        #expect(choices.map(\.id) == starters.map(\.id.rawValue))
    }

    @Test
    func `a choice of the person's own is identified by its option id`() {
        let custom = LoopOption(kind: .trigger, label: "Rent due")

        let choice = OptionList.choices(for: .trigger, saved: [custom]).first

        #expect(choice?.id == custom.optionID)
        #expect(choice?.label == "Rent due")
        #expect(choice?.starterID == nil)
    }

    @Test
    func `a custom trigger and a custom behavior with the same text are separate options`() {
        let trigger = LoopOption(kind: .trigger, label: "A")
        let behavior = LoopOption(kind: .behavior, label: "A")
        let saved = [trigger, behavior]

        let triggers = OptionList.choices(for: .trigger, saved: saved).filter { $0.label == "A" }
        let behaviors = OptionList.choices(for: .behavior, saved: saved).filter { $0.label == "A" }

        #expect(triggers.map(\.id) == [trigger.optionID])
        #expect(behaviors.map(\.id) == [behavior.optionID])
        #expect(trigger.optionID != behavior.optionID)
    }

    @Test
    func `custom options come before the starters, newest first`() {
        let older = LoopOption(kind: .trigger, label: "Call from Mom")
        older.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        let newer = LoopOption(kind: .trigger, label: "Rent due")
        newer.createdAt = Date(timeIntervalSince1970: 1_800_100_000)

        let choices = OptionList.choices(for: .trigger, saved: [older, newer])

        #expect(Array(choices.prefix(2)) == [
            OptionChoice(newer),
            OptionChoice(older),
        ])
        #expect(choices.dropFirst(2).map(\.starterID) == StarterOption.options(for: .trigger).map(\.id))
    }

    /// Step 3 is a feeling check, so the core results keep their places and the person's own never jump above them.
    @Test
    func `custom results come after the core results, oldest first`() {
        let older = LoopOption(kind: .result, label: "Felt silly")
        older.createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = LoopOption(kind: .result, label: "Got a headache")
        newer.createdAt = Date(timeIntervalSince1970: 1_700_100_000)

        let choices = OptionList.choices(for: .result, saved: [newer, older])

        let core = StarterOption.options(for: .result).map(\.id)
        #expect(choices.prefix(core.count).map(\.starterID) == core)
        #expect(Array(choices.dropFirst(core.count)) == [
            OptionChoice(older),
            OptionChoice(newer),
        ])
    }

    @Test
    func `a custom result with a core result's text appears once, in the core result's place`() {
        let relief = StarterOption.with(id: .littleRelief)
        let label = relief.text

        let custom = LoopOption(kind: .result, label: label)

        let choices = OptionList.choices(for: .result, saved: [custom])

        #expect(choices.map(\.starterID) == StarterOption.options(for: .result).map(\.id))
        #expect(choices.count { $0.label == label } == 1)
        #expect(choices.first { $0.label == label }?.mergedIDs == [custom.optionID])
    }

    @Test
    func `a renamed core result keeps its place`() {
        let rename = LoopOption(overriding: .littleRelief, label: "Felt lighter")

        let choices = OptionList.choices(for: .result, saved: [rename])

        #expect(choices.map(\.starterID) == StarterOption.options(for: .result).map(\.id))
        #expect(choices.first { $0.starterID == .littleRelief }?.label == "Felt lighter")
    }

    @Test
    func `a renamed starter shows its new text in the starter's place`() {
        let rename = LoopOption(overriding: .news, label: "World news")

        let choices = OptionList.choices(for: .trigger, saved: [rename])

        let expected = StarterOption.options(for: .trigger).map { starter in
            OptionChoice(starter.id, label: starter.id == .news ? "World news" : starter.text)
        }
        #expect(choices == expected)
    }

    @Test
    func `hidden starters and hidden custom options are left out`() {
        let hiddenStarter = LoopOption(overriding: .news, label: "")
        hiddenStarter.isHidden = true
        let hiddenCustom = LoopOption(kind: .trigger, label: "Rent due")
        hiddenCustom.isHidden = true

        let choices = OptionList.choices(for: .trigger, saved: [hiddenStarter, hiddenCustom])

        #expect(!choices.contains { $0.starterID == .news })
        #expect(!choices.contains { $0.label == "Rent due" })
        #expect(choices.count == StarterOption.options(for: .trigger).count - 1)
    }

    /// Two devices can each save a change to the same starter before they sync.
    @Test
    func `of two changes to the same starter, the one edited last wins, whenever it was created`() {
        let editedLast = LoopOption(overriding: .news, label: "Headlines")
        editedLast.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        editedLast.updatedAt = Date(timeIntervalSince1970: 1_800_200_000)
        let createdLast = LoopOption(overriding: .news, label: "World news")
        createdLast.createdAt = Date(timeIntervalSince1970: 1_800_100_000)
        createdLast.updatedAt = Date(timeIntervalSince1970: 1_800_100_000)

        let choices = OptionList.choices(for: .trigger, saved: [editedLast, createdLast])

        #expect(choices.filter { $0.starterID == .news } == [
            OptionChoice(.news, label: "Headlines")
        ])
    }

    /// Fetch order differs between devices, so a tie must not fall to whichever comes first.
    @Test
    func `when two changes to a starter were edited at the same time, the one created last wins`() {
        let editedAt = Date(timeIntervalSince1970: 1_800_200_000)
        let createdFirst = LoopOption(overriding: .news, label: "World news")
        createdFirst.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        createdFirst.updatedAt = editedAt
        let createdLast = LoopOption(overriding: .news, label: "Headlines")
        createdLast.createdAt = Date(timeIntervalSince1970: 1_800_100_000)
        createdLast.updatedAt = editedAt

        for saved in [[createdFirst, createdLast], [createdLast, createdFirst]] {
            let choices = OptionList.choices(for: .trigger, saved: saved)

            #expect(choices.filter { $0.starterID == .news } == [
                OptionChoice(.news, label: "Headlines")
            ])
        }
    }

    @Test
    func `a custom option with a starter's text appears once, with the custom options`() {
        let news = StarterOption.with(id: .news)
        let label = news.text
        let custom = LoopOption(kind: .trigger, label: label)

        let choices = OptionList.choices(for: .trigger, saved: [custom])

        #expect(choices.first?.id == custom.optionID)
        #expect(choices.first?.mergedIDs == ["trigger.news"])
        #expect(choices.count { $0.label == label } == 1)
    }

    @Test
    func `a custom option matching a starter only in another case appears alongside it`() {
        let news = StarterOption.with(id: .news)
        let typed = news.text.lowercased()
        let custom = LoopOption(kind: .trigger, label: typed)

        let choices = OptionList.choices(for: .trigger, saved: [custom])

        #expect(choices.first == OptionChoice(custom))
        #expect(choices.contains { $0.starterID == .news })
    }

    /// Two devices can each save the same text before they sync.
    @Test
    func `two custom options with the same text appear once, as the newer`() {
        let older = LoopOption(kind: .trigger, label: "Rent due")
        older.createdAt = Date(timeIntervalSince1970: 1_800_000_000)
        let newer = LoopOption(kind: .trigger, label: "Rent due")
        newer.createdAt = Date(timeIntervalSince1970: 1_800_100_000)

        let choices = OptionList.choices(for: .trigger, saved: [older, newer])

        #expect(choices.first?.id == newer.optionID)
        #expect(choices.first?.mergedIDs == [older.optionID])
        #expect(choices.count { $0.label == "Rent due" } == 1)
    }

    @Test
    func `a starter renamed to another starter's text appears once, in its own place`() {
        // Deadline comes before News, so the rename is the first place that text appears.
        let news = StarterOption.with(id: .news)
        let label = news.text
        let rename = LoopOption(overriding: .deadline, label: label)

        let choices = OptionList.choices(for: .trigger, saved: [rename])

        let shown = choices.filter { $0.label == label }
        #expect(shown.map(\.id) == ["trigger.deadline"])
        #expect(shown.map(\.mergedIDs) == [["trigger.news"]])
        #expect(choices.count == StarterOption.options(for: .trigger).count - 1)
    }

    @Test
    func `only options of the requested kind appear`() {
        let behavior = LoopOption(kind: .behavior, label: "Paced around")

        let choices = OptionList.choices(for: .trigger, saved: [behavior])

        #expect(choices.map(\.starterID) == StarterOption.options(for: .trigger).map(\.id))
    }

    // MARK: - Hidden options

    @Test
    func `a hidden custom option is found by its text`() {
        let hidden = LoopOption(kind: .trigger, label: "Rent due")
        hidden.isHidden = true

        #expect(OptionList.hiddenOption(matching: "Rent due", for: .trigger, saved: [hidden]) === hidden)
    }

    @Test
    func `a hidden starter is found by the text it showed when hidden`() {
        let hide = LoopOption(overriding: .news, label: "World news")
        hide.isHidden = true

        #expect(OptionList.hiddenOption(matching: "World news", for: .trigger, saved: [hide]) === hide)
    }

    @Test
    func `only a hidden option of the same kind with exactly the same text is found`() {
        let visible = LoopOption(kind: .trigger, label: "Rent due")
        let otherKind = LoopOption(kind: .behavior, label: "Paced around")
        otherKind.isHidden = true
        let hidden = LoopOption(kind: .trigger, label: "Call from Mom")
        hidden.isHidden = true
        let saved = [visible, otherKind, hidden]

        #expect(OptionList.hiddenOption(matching: "Rent due", for: .trigger, saved: saved) == nil)
        #expect(OptionList.hiddenOption(matching: "Paced around", for: .trigger, saved: saved) == nil)
        #expect(OptionList.hiddenOption(matching: "call from mom", for: .trigger, saved: saved) == nil)
    }

    /// Only the starter's newest change counts, so an older hide that a later rename replaced is not hidden.
    @Test
    func `a starter hidden once but changed since is not found`() {
        let hide = LoopOption(overriding: .news, label: "News")
        hide.isHidden = true
        hide.updatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let rename = LoopOption(overriding: .news, label: "Headlines")
        rename.updatedAt = Date(timeIntervalSince1970: 1_800_100_000)

        #expect(OptionList.hiddenOption(matching: "News", for: .trigger, saved: [hide, rename]) == nil)
    }
}
