import os
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var model: RootViewModel

    var body: some View {
        TabView(selection: Binding(get: { model.selectedTab }, set: { model.select($0) })) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView(root: model)
            }
            Tab("Learn", systemImage: "book", value: .learn) {
                LearnView { model.openLesson($0) }
            }
            Tab("Insights", systemImage: "chart.bar", value: .insights) {
                InsightsView {
                    model.select(.log)
                }
            }
            // Selecting this tab opens the sheet; RootViewModel never makes it the selection.
            // Keeps the system's glass look rather than the mockup's accent fill (ADR 0003).
            Tab("Log a loop", systemImage: "square.and.pencil", value: AppTab.log, role: .prominent) {
                Color.clear
            }
        }
        .tint(.theme(.accent))
        .sheet(isPresented: $model.isLogSheetPresented, onDismiss: model.screenClosed) {
            LogLoopView {
                model.showInsights()
            }
        }
        // Every screen over the tabs opens here, so the reminder or a lesson's task can close one and open another.
        .fullScreenCover(item: $model.readingLesson, onDismiss: lessonClosed) { lesson in
            LessonReaderView(lesson: lesson, progress: LessonProgressStore(context: modelContext)) { task in
                model.finishLesson(then: task)
            } backToLearn: {
                model.backToLearn()
            }
        }
        .fullScreenCover(item: $model.runningTool, onDismiss: model.screenClosed) { tool in
            ToolRunView(tool: tool, sessions: SessionStore(context: modelContext))
        }
        .sheet(isPresented: $model.isSettingsPresented, onDismiss: model.screenClosed) {
            SettingsView(scheduler: reminderScheduler)
        }
        .sheet(isPresented: $model.isHelpPresented, onDismiss: model.screenClosed) {
            HelpView()
        }
        // Progress can arrive from another device while the app was away; the reminder should name the right lesson.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await reminder.refresh() }
            }
        }
    }

    /// The reminder names the next lesson as it stands when it's scheduled.
    private var reminderScheduler: NotificationReminderScheduler {
        NotificationReminderScheduler { [modelContext] in
            do {
                return try LessonProgressStore(context: modelContext).nextLesson(in: .bundled)
            } catch {
                // Treated as a finished course: the reminder then invites a log rather than naming a lesson.
                Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Reminder")
                    .error("Couldn't find the next lesson for the reminder: \(error)")
                return nil
            }
        }
    }

    private var reminder: CourseReminder {
        CourseReminder(settings: ReminderSettings(defaults: .standard), scheduler: reminderScheduler)
    }

    /// A finished lesson moves the reminder on to the next one.
    private func lessonClosed() {
        model.screenClosed()
        Task { await reminder.refresh() }
    }
}

#if DEBUG
    #Preview {
        RootView(model: RootViewModel())
            .modelContainer(AppModelContainer.preview)
    }
#endif
