@testable import LooseningWorry
import Testing

@MainActor
struct RootViewModelTests {
    @Test
    func `starts on Home with the Log sheet closed`() {
        let model = RootViewModel(onboarding: .finished)

        #expect(model.selectedTab == .home)
        #expect(model.isLogSheetPresented == false)
    }

    @Test(arguments: [AppTab.learn, .insights, .home])
    func `selecting a destination tab switches to it`(tab: AppTab) {
        let model = RootViewModel(onboarding: .finished)

        model.select(.learn)
        model.select(tab)

        #expect(model.selectedTab == tab)
        #expect(model.isLogSheetPresented == false)
    }

    @Test
    func `selecting Log opens the sheet without leaving the current tab`() {
        let model = RootViewModel(onboarding: .finished)
        model.select(.insights)

        model.select(.log)

        #expect(model.isLogSheetPresented)
        #expect(model.selectedTab == .insights)
    }

    @Test
    func `closing the Log sheet returns to the tab it opened over`() {
        let model = RootViewModel(onboarding: .finished)
        model.select(.insights)
        model.select(.log)

        model.isLogSheetPresented = false

        #expect(model.selectedTab == .insights)
    }

    /// Nice catch's weekly count leads to Insights, closing the logger on the way.
    @Test
    func `showing Insights from the logger closes it and switches to Insights`() {
        let model = RootViewModel(onboarding: .finished)
        model.select(.log)

        model.showInsights()

        #expect(model.isLogSheetPresented == false)
        #expect(model.selectedTab == .insights)
    }

    @Test
    func `tapping the daily reminder opens the logger`() {
        let model = RootViewModel(onboarding: .finished)
        model.select(.learn)

        model.openNotification(identifier: ReminderNotification.identifier, lessonDay: nil)

        #expect(model.isLogSheetPresented)
        #expect(model.selectedTab == .learn)
    }

    @Test
    func `tapping a lesson reminder opens that lesson`() {
        let model = RootViewModel(onboarding: .finished)

        model.openNotification(identifier: ReminderNotification.identifier, lessonDay: 3)

        #expect(model.readingLesson?.day == 3)
        #expect(!model.isLogSheetPresented)
    }

    @Test
    func `tapping any other notification leaves the app as it was`() {
        let model = RootViewModel(onboarding: .finished)

        model.openNotification(identifier: "something.else", lessonDay: nil)

        #expect(model.isLogSheetPresented == false)
        #expect(model.selectedTab == .home)
    }

    private func lesson(_ day: Int) throws -> Lesson {
        try #require(LessonCatalog.bundled.lesson(day: day))
    }

    @Test
    func `opening a lesson shows it in the reader`() throws {
        let model = RootViewModel(onboarding: .finished)

        try model.openLesson(lesson(2))

        #expect(model.readingLesson?.day == 2)
    }

    /// The reader closes first; the task opens once it has gone, as iOS shows one screen over the tabs at a time.
    @Test(arguments: [
        (LessonAction.logLoop, Destination.logger),
        (.openInsights, .insights),
        (.tool(.curious), .tool(.curious)),
        (.tool(.breathe), .tool(.breathe)),
        (.tool(.noteIt), .tool(.noteIt)),
        (.tool(.beKind), .tool(.beKind)),
        (.openSettings, .settings),
    ])
    func `finishing a lesson with its task opens the task once the reader has closed`(
        action: LessonAction,
        destination: Destination,
    ) throws {
        let model = RootViewModel(onboarding: .finished)
        try model.openLesson(lesson(2))

        model.finishLesson(then: action)
        #expect(model.readingLesson == nil)
        #expect(Destination.showing(in: model) == nil)

        model.screenClosed()
        #expect(Destination.showing(in: model) == destination)
    }

    @Test
    func `finishing a lesson without its task just closes the reader`() throws {
        let model = RootViewModel(onboarding: .finished)
        try model.openLesson(lesson(2))

        model.finishLesson(then: nil)
        model.screenClosed()

        #expect(model.readingLesson == nil)
        #expect(Destination.showing(in: model) == nil)
        #expect(model.selectedTab == .home)
    }

    @Test
    func `going back to Learn from a finished lesson closes the reader and shows Learn`() throws {
        let model = RootViewModel(onboarding: .finished)
        try model.openLesson(lesson(2))

        model.backToLearn()
        model.screenClosed()

        #expect(model.readingLesson == nil)
        #expect(model.selectedTab == .learn)
        #expect(Destination.showing(in: model) == nil)
    }

    /// The reminder can open the logger while a finished lesson is still closing; its task mustn't open afterwards.
    @Test
    func `a reminder opening the logger drops a finished lesson's task`() throws {
        let model = RootViewModel(onboarding: .finished)
        try model.openLesson(lesson(2))
        model.finishLesson(then: .tool(.breathe))

        model.select(.log)
        model.screenClosed()

        #expect(model.runningTool == nil)
        #expect(model.isLogSheetPresented)
    }

    /// iOS ignores a new screen while another is still closing, so the reminder closes what's open and waits for it.
    @Test(arguments: Covering.allCases)
    func `the daily reminder over another screen opens the logger once that screen has gone`(covering: Covering) throws {
        let model = RootViewModel(onboarding: .finished)
        try covering.open(in: model)

        model.openNotification(identifier: ReminderNotification.identifier, lessonDay: nil)
        #expect(!covering.isOpen(in: model))
        #expect(!model.isLogSheetPresented)

        model.screenClosed()
        #expect(model.isLogSheetPresented)
    }

    @Test(arguments: Covering.allCases)
    func `a lesson reminder over another screen opens the lesson once that screen has gone`(covering: Covering) throws {
        let model = RootViewModel(onboarding: .finished)
        try covering.open(in: model)

        model.openNotification(identifier: ReminderNotification.identifier, lessonDay: 3)
        #expect(!covering.isOpen(in: model))
        #expect(model.readingLesson == nil)

        model.screenClosed()
        #expect(model.readingLesson?.day == 3)
    }

    @Test
    func `opening Help shows it over the tabs`() {
        let model = RootViewModel(onboarding: .finished)

        model.openHelp()

        #expect(model.isHelpPresented)
    }

    /// One screen over the tabs, as the reminder might find the app.
    enum Covering: CaseIterable {
        case logger, lesson, tool, settings, help

        @MainActor
        func open(in model: RootViewModel) throws {
            switch self {
            case .logger: model.select(.log)
            case .lesson: try model.openLesson(#require(LessonCatalog.bundled.lesson(day: 5)))
            case .tool: model.openTool(.breathe)
            case .settings: model.openSettings()
            case .help: model.openHelp()
            }
        }

        @MainActor
        func isOpen(in model: RootViewModel) -> Bool {
            switch self {
            case .logger: model.isLogSheetPresented
            case .lesson: model.readingLesson != nil
            case .tool: model.runningTool != nil
            case .settings: model.isSettingsPresented
            case .help: model.isHelpPresented
            }
        }
    }

    enum Destination: Equatable {
        case logger, insights, settings
        case tool(QuickTool)

        @MainActor
        static func showing(in model: RootViewModel) -> Destination? {
            if model.isLogSheetPresented {
                return .logger
            }
            if model.isSettingsPresented {
                return .settings
            }
            if let tool = model.runningTool {
                return .tool(tool)
            }
            if model.selectedTab == .insights {
                return .insights
            }
            return nil
        }
    }
}
