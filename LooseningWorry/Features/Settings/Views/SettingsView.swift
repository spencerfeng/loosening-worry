import SwiftUI

/// Settings, opened from the gear on Home or a lesson's task: the daily check-in, the person's options and a way to
/// Help. Later sections (Face ID, export, purchases, About) join as their own sections. All wording is a draft.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: SettingsViewModel
    @State private var isShowingOptions = false
    @State private var isShowingHelp = false

    init(scheduler: any ReminderScheduler) {
        _model = State(initialValue: SettingsViewModel(
            settings: ReminderSettings(defaults: .standard),
            scheduler: scheduler,
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: reminderSwitch) {
                        Text(LocalizedStringResource("settings.reminder", defaultValue: "Daily check-in"))
                    }
                    if model.isReminderOn {
                        DatePicker(selection: reminderTime, displayedComponents: .hourAndMinute) {
                            Text(LocalizedStringResource("settings.reminder.time", defaultValue: "Time"))
                        }
                    }
                    if model.notificationsOff {
                        NotificationsOffNote()
                    }
                    if model.reminderFailed {
                        Text(LocalizedStringResource(
                            "settings.reminder.failed",
                            defaultValue: "Couldn't set the check-in. Try again.",
                        ))
                        .font(.theme(.footnote))
                        .foregroundStyle(.theme(.redOnTint))
                    }
                } header: {
                    Text(LocalizedStringResource("settings.reminders", defaultValue: "Notifications"))
                }

                Section {
                    Button {
                        isShowingOptions = true
                    } label: {
                        SettingsRow(
                            title: LocalizedStringResource("settings.options", defaultValue: "Your options"),
                            symbol: "slider.horizontal.3",
                            symbolColor: .accent,
                        )
                    }
                }

                Section {
                    Button {
                        isShowingHelp = true
                    } label: {
                        SettingsRow(
                            title: LocalizedStringResource("settings.help", defaultValue: "Get help"),
                            symbol: "lifepreserver",
                            symbolColor: .help,
                        )
                    }
                } header: {
                    Text(LocalizedStringResource("settings.support", defaultValue: "Support"))
                }
            }
            .font(.theme(.body))
            .foregroundStyle(.theme(.textPrimary))
            .tint(.theme(.accent))
            .scrollContentBackground(.hidden)
            .background(.theme(.background))
            .navigationTitle(Text(LocalizedStringResource("settings.title", defaultValue: "Settings")))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingOptions) {
                EditOptionsView(kind: .trigger)
            }
            .sheet(isPresented: $isShowingHelp) {
                HelpView()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(LocalizedStringResource("settings.done", defaultValue: "Done"))
                    }
                }
            }
        }
        .task { await model.refresh() }
        // The person may come back from iOS Settings having allowed notifications.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await model.refresh() }
            }
        }
    }

    private var reminderSwitch: Binding<Bool> {
        Binding(get: { model.isReminderOn }, set: { on in Task { await model.setReminder(on: on) } })
    }

    private var reminderTime: Binding<Date> {
        Binding(get: { model.reminderTime.date() }, set: { date in
            Task { await model.setTime(ReminderTime(date: date)) }
        })
    }
}

/// Why the reminder can't be on, and the way to iOS Settings, where only the person can allow notifications.
private struct NotificationsOffNote: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringResource(
                "settings.notificationsOff",
                defaultValue: "Notifications are off for Loosening Worry. Turn them on in Settings for your check-in.",
            ))
            .font(.theme(.footnote))
            .foregroundStyle(.theme(.textSecondary))
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                Button {
                    openURL(url)
                } label: {
                    Text(LocalizedStringResource("settings.notificationsOff.open", defaultValue: "Open Settings"))
                        .font(.theme(.callout))
                        .foregroundStyle(.theme(.accentText))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

/// A row that opens something: an icon, its title and a chevron.
private struct SettingsRow: View {
    let title: LocalizedStringResource
    let symbol: String
    let symbolColor: Theme.ColorRole

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .fontWeight(.semibold)
                .foregroundStyle(.theme(symbolColor))
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .foregroundStyle(.theme(.textPrimary))
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.theme(.textTertiary))
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
    }
}

#if DEBUG
    #Preview {
        SettingsView(scheduler: NotificationReminderScheduler { nil })
            .modelContainer(AppModelContainer.preview)
    }
#endif
