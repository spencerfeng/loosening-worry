@testable import LooseningWorry
import Testing

/// Step 3 of the check-in: what's having the biggest impact.
@MainActor
struct CheckInContextTests {
    private static let work = OptionChoice(.contextWork, label: "Work")
    private static let money = OptionChoice(.contextMoney, label: "Money")

    @Test
    func `the steps go words then contexts, and back the same way`() {
        let model = CheckInViewModel()
        model.choose(.unpleasant)

        model.next()
        #expect(model.step == .feelings)
        model.next()
        #expect(model.step == .contexts)
        model.next()
        #expect(model.step == .contexts)

        model.back()
        #expect(model.step == .feelings)
        model.back()
        #expect(model.step == .pleasantness)
    }

    @Test
    func `only step 3's Done saves`() {
        let model = CheckInViewModel()
        model.choose(.unpleasant)
        model.next()
        var stored: [CheckIn] = []

        model.finish { stored.append($0) }

        #expect(stored.isEmpty)
        #expect(model.step == .feelings)
    }

    @Test
    func `contexts toggle on and off, and save in the order picked with their text`() {
        let model = onContexts()
        model.toggle(Self.work)
        model.toggle(Self.money)
        model.toggle(OptionChoice(id: "own-1", label: "Moving house"))
        model.toggle(Self.money)
        var stored: [CheckIn] = []

        model.finish { stored.append($0) }

        #expect(stored.first?.contextIDs == ["context.work", "own-1"])
        #expect(stored.first?.contextLabels == ["Work", "Moving house"])
        #expect(model.summary == ["Unpleasant", "Work", "Moving house"])
    }

    @Test
    func `step 3 is optional`() {
        let model = onContexts()
        var stored: [CheckIn] = []

        model.finish { stored.append($0) }

        #expect(stored.first?.contextIDs == [])
        #expect(model.suggestion != nil)
    }

    /// A choice can show copies from two devices under one text; picking it under any of them counts.
    @Test
    func `a context picked under a merged id shows as picked`() {
        let model = onContexts()
        model.toggle(OptionChoice(id: "copy-b", label: "Moving house"))
        var merged = OptionChoice(id: "copy-a", label: "Moving house")
        merged.mergedIDs = ["copy-b"]

        #expect(model.isPicked(merged))

        model.toggle(merged)
        #expect(model.contexts.isEmpty)
    }

    @Test
    func `adding their own saves it, picks it and closes the field`() {
        let model = onContexts()
        model.ownDraft.toggle()
        model.ownDraft.text = "  Moving house "
        var saved: [String] = []

        model.addOwn { label in
            saved.append(label)
            return OptionChoice(id: "own-1", label: label)
        }

        #expect(saved == ["Moving house"])
        #expect(model.contexts == [OptionChoice(id: "own-1", label: "Moving house")])
        #expect(!model.ownDraft.isOpen)
        #expect(model.ownDraft.text.isEmpty)
    }

    @Test
    func `adding text that's already a choice picks that choice instead`() {
        let model = onContexts()
        model.ownDraft.toggle()
        model.ownDraft.text = "Work"
        var saved: [String] = []

        model.addOwn { label in
            saved.append(label)
            return OptionChoice(id: "own-1", label: label)
        }
        model.ownDraft.toggle()
        model.ownDraft.text = "Work"
        model.addOwn { _ in OptionChoice(id: "own-2", label: "Work") }

        #expect(saved.isEmpty)
        #expect(model.contexts == [Self.work])
    }

    @Test
    func `blank text adds nothing`() {
        let model = onContexts()
        model.ownDraft.toggle()
        model.ownDraft.text = "   "

        #expect(!model.ownDraft.canAdd)
        model.addOwn { _ in OptionChoice(id: "own-1", label: "") }

        #expect(model.contexts.isEmpty)
        #expect(model.ownDraft.isOpen)
    }

    @Test
    func `if their own can't be saved, it's still picked, shown and kept`() {
        struct Failed: Error {}
        let model = onContexts()
        model.ownDraft.toggle()
        model.ownDraft.text = "Moving house"

        model.addOwn { _ in throw Failed() }

        #expect(model.contexts.map(\.label) == ["Moving house"])
        #expect(model.ownDraft.unsavedLabel == "Moving house")
        #expect(model.contextChips.map(\.label) == ["Money", "Moving house", "Work"])

        model.showContextChoices([Self.work])
        #expect(model.contexts.map(\.label) == ["Moving house"])
    }

    @Test
    func `an unsaved context unpicked stays on show, and typing it again picks it`() throws {
        struct Failed: Error {}
        let model = onContexts()
        model.ownDraft.toggle()
        model.ownDraft.text = "Moving house"
        model.addOwn { _ in throw Failed() }
        let unsaved = try #require(model.contexts.first)
        var saved: [String] = []

        model.toggle(unsaved)
        #expect(model.contexts.isEmpty)
        #expect(model.contextChips.map(\.label) == ["Money", "Moving house", "Work"])

        model.ownDraft.toggle()
        model.ownDraft.text = "Moving house"
        model.addOwn { label in
            saved.append(label)
            return OptionChoice(id: "own-1", label: label)
        }

        #expect(saved.isEmpty)
        #expect(model.contexts == [unsaved])
        #expect(model.contextChips.count == 3)
    }

    @Test
    func `a context removed on the Edit screen is unpicked`() {
        let model = onContexts()
        model.toggle(Self.work)
        model.toggle(Self.money)

        model.showContextChoices([Self.money])

        #expect(model.contexts == [Self.money])
    }

    /// A context added on the Edit screen comes back picked, like one added on the step.
    @Test
    func `a context picked from elsewhere is picked once`() {
        let model = onContexts()

        model.pick(Self.work)
        model.pick(Self.work)

        #expect(model.contexts == [Self.work])
    }

    @Test
    func `an unsaved context gives way to a saved one with its text, keeping the pick`() {
        struct Failed: Error {}
        let model = onContexts()
        model.toggle(Self.money)
        model.ownDraft.toggle()
        model.ownDraft.text = "Moving house"
        model.addOwn { _ in throw Failed() }
        let synced = OptionChoice(id: "own-9", label: "Moving house")

        model.showContextChoices([Self.work, Self.money, synced])

        #expect(model.contextChips.map(\.label) == ["Money", "Moving house", "Work"])
        #expect(model.contexts == [Self.money, synced])
    }

    @Test
    func `tapping Done adds the text still in the field, then saves`() {
        let model = onContexts()
        model.ownDraft.toggle()
        model.ownDraft.text = "Moving house"
        var stored: [CheckIn] = []

        model.finish(addingDraftWith: { OptionChoice(id: "own-1", label: $0) }, { stored.append($0) })

        #expect(stored.first?.contextLabels == ["Moving house"])
        #expect(stored.first?.contextIDs == ["own-1"])
    }

    @Test
    func `going back from step 3 clears the contexts picked and closes the field, keeping the words`() {
        let model = CheckInViewModel()
        model.choose(.unpleasant)
        model.next()
        model.toggle(.anxious)
        model.next()
        model.toggle(Self.work)
        model.ownDraft.toggle()
        model.ownDraft.text = "Moving"

        model.back()

        #expect(model.step == .feelings)
        #expect(model.contexts.isEmpty)
        #expect(model.feelings == [.anxious])
        #expect(!model.ownDraft.isOpen)
        #expect(model.ownDraft.text.isEmpty)
    }

    /// A check-in on step 3, after unpleasant and no words, showing `choices`.
    private func onContexts(showing choices: [OptionChoice] = [work, money]) -> CheckInViewModel {
        let model = CheckInViewModel()
        model.choose(.unpleasant)
        model.next()
        model.next()
        model.showContextChoices(choices)
        return model
    }
}
