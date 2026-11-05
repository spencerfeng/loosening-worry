@testable import LooseningWorry
import Testing

/// "Nothing yet, I'm in it now": the person meets the urge with a tool instead of logging a habit that already ran.
@MainActor
struct LogLoopMeetTests {
    @Test
    func `nothing yet keeps the trigger and asks which tool to meet the urge with`() {
        let model = LogLoopViewModel()
        model.pick(.news)

        model.meetIt()

        #expect(model.isMeeting)
        #expect(model.answer(for: .trigger)?.id == "trigger.news")
        #expect(model.answer(for: .behavior) == nil)
        #expect(model.currentStep == .behavior)
    }

    @Test
    func `going back from the tools returns to the habits, trigger kept`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.meetIt()

        model.stopMeeting()

        #expect(model.isMeeting == false)
        #expect(model.answer(for: .trigger)?.id == "trigger.news")
        #expect(model.currentStep == .behavior)
    }

    /// The summary card can reopen step 1 at any time; the tools belong to step 2.
    @Test
    func `reopening step 1 leaves the tools`() {
        let model = LogLoopViewModel()
        model.pick(.news)
        model.meetIt()

        model.goTo(.trigger)

        #expect(model.isMeeting == false)
        #expect(model.currentStep == .trigger)
    }
}
