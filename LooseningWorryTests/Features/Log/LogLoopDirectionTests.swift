@testable import LooseningWorry
import Testing

/// Which way the logger moves between steps, so a step comes in from the side it lies on.
@MainActor
struct LogLoopDirectionTests {
    @Test
    func `reopening an earlier step moves back`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.pick(.scrolled)

        model.goTo(.trigger)

        #expect(model.direction == .back)
    }

    /// With every step answered, the summary card can reopen any of them, later ones included.
    @Test
    func `reopening a later step moves forward`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.pick(.scrolled)
        model.pick(.moreWorry)
        model.goTo(.trigger)

        model.goTo(.result)

        #expect(model.direction == .forward)
    }

    @Test
    func `the logger starts moving forward, and picking from the start keeps it so`() {
        let model = LogLoopViewModel()
        #expect(model.direction == .forward)

        model.pick(.news)

        #expect(model.direction == .forward)
    }

    @Test
    func `answering a reopened step moves forward`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.goTo(.trigger)

        model.pick(.deadline)

        #expect(model.direction == .forward)
    }

    /// Every row on the summary card can be tapped, so the person can answer step 3 first; picking then returns to
    /// the first step still unanswered, an earlier one.
    @Test
    func `picking after jumping ahead moves back to the step still unanswered`() {
        let model = LogLoopViewModel()
        model.goTo(.result)

        model.pick(.moreWorry)

        #expect(model.currentStep == .trigger)
        #expect(model.direction == .back)
    }

    /// The tools stand in for the habits, a little further on, so reopening the habits from the summary card goes back
    /// as the tools' own back does.
    @Test
    func `reopening the habits while the tools show moves back`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.meetIt()

        model.goTo(.behavior)

        #expect(model.direction == .back)
    }

    @Test
    func `going back from the tools to the habits moves back`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.meetIt()

        model.stopMeeting()

        #expect(model.direction == .back)
    }

    @Test
    func `meeting it moves forward to the tools`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.meetIt()
        model.stopMeeting()

        model.meetIt()

        #expect(model.direction == .forward)
    }
}
