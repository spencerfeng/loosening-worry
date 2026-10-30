import Observation

enum AppTab: Hashable {
    case home, learn, insights
    /// An action, not a destination: `RootViewModel` never makes it the selection.
    case log
}

/// The tab bar and the one screen iOS shows over it at a time: the logger, a lesson, a tool, Settings or Help.
@Observable @MainActor
final class RootViewModel {
    private(set) var selectedTab: AppTab = .home
    var isLogSheetPresented = false
    /// The lesson open in the reader, over whichever tab it was opened from.
    var readingLesson: Lesson?
    var runningTool: QuickTool?
    var isSettingsPresented = false
    var isHelpPresented = false
    /// What opens once the screen showing now has closed; iOS ignores a new screen while another is still going.
    private var next: Next?

    private enum Next {
        case logger
        case lesson(Lesson)
        case task(LessonAction)
    }

    /// Log is an action, not a destination: it opens the sheet over whichever tab is showing. It can come from the
    /// daily reminder while anything is open.
    func select(_ tab: AppTab) {
        if tab == .log {
            show(.logger)
        } else {
            selectedTab = tab
        }
    }

    /// Closes the logger and switches to Insights, for Nice catch's weekly count.
    func showInsights() {
        isLogSheetPresented = false
        selectedTab = .insights
    }

    /// Tapping the daily reminder opens the lesson it names, or the logger once the course is done, over any tab.
    func openNotification(identifier: String, lessonDay: Int?) {
        guard identifier == ReminderNotification.identifier else { return }
        if let lessonDay, let lesson = LessonCatalog.bundled.lesson(day: lessonDay) {
            show(.lesson(lesson))
        } else {
            show(.logger)
        }
    }

    func openLesson(_ lesson: Lesson) {
        readingLesson = lesson
    }

    func openTool(_ tool: QuickTool) {
        runningTool = tool
    }

    func openSettings() {
        isSettingsPresented = true
    }

    func openHelp() {
        isHelpPresented = true
    }

    /// Closes the reader; `task`, if any, opens in `screenClosed()` once it has gone.
    func finishLesson(then task: LessonAction?) {
        next = task.map(Next.task)
        readingLesson = nil
    }

    /// The done screen's way out: closes the reader onto the course.
    func backToLearn() {
        next = nil
        readingLesson = nil
        selectedTab = .learn
    }

    /// A screen over the tabs has finished closing: opens whatever was waiting for it.
    func screenClosed() {
        guard let waiting = next, !isShowingScreen else { return }
        next = nil
        open(waiting)
    }

    private var isShowingScreen: Bool {
        isLogSheetPresented || readingLesson != nil || runningTool != nil || isSettingsPresented || isHelpPresented
    }

    /// Opens `screen` now, or closes what's showing and opens it once that has gone. Anything already waiting, such
    /// as a finished lesson's task, is dropped.
    private func show(_ screen: Next) {
        if isShowingScreen {
            isLogSheetPresented = false
            readingLesson = nil
            runningTool = nil
            isSettingsPresented = false
            isHelpPresented = false
            next = screen
        } else {
            next = nil
            open(screen)
        }
    }

    private func open(_ screen: Next) {
        switch screen {
        case .logger: isLogSheetPresented = true
        case let .lesson(lesson): openLesson(lesson)
        case .task(.logLoop): isLogSheetPresented = true
        case .task(.openInsights): selectedTab = .insights
        case let .task(.tool(tool)): openTool(tool)
        case .task(.openSettings), .task(.setReminder): openSettings()
        }
    }
}
