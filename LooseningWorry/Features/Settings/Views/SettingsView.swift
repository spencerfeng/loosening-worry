import SwiftUI

/// Settings, opened from the gear on Home or a lesson's task: the daily check-in, the app lock, the person's options
/// and a way to Help. Each row leads with its icon on a tint, like the tools on Home. All wording is a draft.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: SettingsViewModel
    @State private var isShowingOptions = false
    @State private var isShowingHelp = false
    let lock: AppLockViewModel

    init(scheduler: any ReminderScheduler, lock: AppLockViewModel) {
        _model = State(initialValue: SettingsViewModel(
            settings: ReminderSettings(defaults: .standard),
            scheduler: scheduler,
        ))
        self.lock = lock
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: reminderSwitch) {
                        SettingsLabel(
                            title: LocalizedStringResource("settings.reminder", defaultValue: "Daily check-in"),
                            symbol: "bell",
                            tint: .amberTint,
                            ink: .amberStrong,
                        )
                    }
                    .settingsRow()
                    if model.isReminderOn {
                        DatePicker(selection: reminderTime, displayedComponents: .hourAndMinute) {
                            Text(LocalizedStringResource("settings.reminder.time", defaultValue: "Time"))
                                .font(.theme(.headline))
                                .padding(.leading, SettingsLabel.textInset)
                        }
                        .settingsRow()
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
                    SettingsHeader(LocalizedStringResource("settings.reminders", defaultValue: "Notifications"))
                } footer: {
                    SettingsFooter(LocalizedStringResource(
                        "settings.reminder.footer",
                        defaultValue: "A gentle nudge each day to pause and notice what worry's been up to.",
                    ))
                }

                LockSection(lock: lock)

                Section {
                    Button {
                        isShowingOptions = true
                    } label: {
                        SettingsLabel(
                            title: LocalizedStringResource("settings.options", defaultValue: "Your options"),
                            symbol: "slider.horizontal.3",
                            tint: .accentTint,
                            ink: .accentText,
                            opensScreen: true,
                        )
                    }
                    .settingsRow()
                } footer: {
                    SettingsFooter(LocalizedStringResource(
                        "settings.options.footer",
                        defaultValue: "Add, hide or bring back the triggers, behaviors and results you log.",
                    ))
                }
                // No header holds this card away from the footer above, so it takes a wider gap.
                .listSectionSpacing(21)

                Section {
                    Button {
                        isShowingHelp = true
                    } label: {
                        SettingsLabel(
                            title: LocalizedStringResource("settings.help", defaultValue: "Get help"),
                            symbol: "lifepreserver",
                            tint: .redTint,
                            ink: .help,
                            opensScreen: true,
                        )
                    }
                    .settingsRow()
                } header: {
                    SettingsHeader(LocalizedStringResource("settings.support", defaultValue: "Support"))
                }
                // Undoes most of the wider gap Your options takes, so Support sits like Privacy.
                .listSectionSpacing(2)
            }
            .foregroundStyle(.theme(.textPrimary))
            // The design's rows are 56 points: the 34-point icon with 11 above and below (`settingsRow()`).
            .environment(\.defaultMinListRowHeight, 56)
            .listSectionSpacing(8)
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

/// The lock switch, named after how this device unlocks. Without a passcode it's off and can't be turned on, and the
/// footer says how to set one.
private struct LockSection: View {
    let lock: AppLockViewModel

    var body: some View {
        // Without a passcode nothing can lock the app, whatever the hardware, so the switch names that.
        let shown = lock.method ?? .passcode
        Section {
            Toggle(isOn: lockSwitch) {
                SettingsLabel(title: shown.switchTitle, symbol: shown.symbol, tint: .greenTint, ink: .greenStrong)
            }
            .disabled(lock.method == nil)
            .settingsRow()
        } header: {
            SettingsHeader(LocalizedStringResource("settings.privacy", defaultValue: "Privacy"))
        } footer: {
            SettingsFooter(lock.method?.footer ?? LocalizedStringResource(
                "settings.lock.noPasscode",
                defaultValue: "Set a passcode in iOS Settings to lock Loosening Worry.",
            ))
        }
    }

    private var lockSwitch: Binding<Bool> {
        Binding(get: { lock.isOn }, set: { on in Task { await lock.setLock(on: on) } })
    }
}

/// How the lock is named in Settings. Each is a whole sentence, so translators see it as one.
private extension LockMethod {
    var switchTitle: LocalizedStringResource {
        switch self {
        case .faceID: LocalizedStringResource("settings.lock.faceID", defaultValue: "Lock with Face ID")
        case .touchID: LocalizedStringResource("settings.lock.touchID", defaultValue: "Lock with Touch ID")
        case .opticID: LocalizedStringResource("settings.lock.opticID", defaultValue: "Lock with Optic ID")
        case .passcode: LocalizedStringResource("settings.lock.passcode", defaultValue: "Lock with passcode")
        }
    }

    var footer: LocalizedStringResource {
        switch self {
        case .faceID: LocalizedStringResource(
                "settings.lock.faceID.footer",
                defaultValue: """
                Asks for Face ID, or your passcode, when you open Loosening Worry or come back after a \
                minute away.
                """,
            )
        case .touchID: LocalizedStringResource(
                "settings.lock.touchID.footer",
                defaultValue: """
                Asks for Touch ID, or your passcode, when you open Loosening Worry or come back after a \
                minute away.
                """,
            )
        case .opticID: LocalizedStringResource(
                "settings.lock.opticID.footer",
                defaultValue: """
                Asks for Optic ID, or your passcode, when you open Loosening Worry or come back after a \
                minute away.
                """,
            )
        case .passcode: LocalizedStringResource(
                "settings.lock.passcode.footer",
                defaultValue: "Asks for your passcode when you open Loosening Worry or come back after a minute away.",
            )
        }
    }
}

/// A row's icon on its tint, then its title; a row that opens another screen ends in a chevron.
private struct SettingsLabel: View {
    /// Where a row's words start, past the icon, for rows without one to line up with.
    static let textInset: CGFloat = 46

    let title: LocalizedStringResource
    let symbol: String
    let tint: Theme.ColorRole
    let ink: Theme.ColorRole
    var opensScreen = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.theme(ink))
                .frame(width: 34, height: 34)
                .background(.theme(tint), in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            Text(title)
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textPrimary))
            if opensScreen {
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.theme(.textTertiary))
                    .accessibilityHidden(true)
            }
        }
        .contentShape(.rect)
    }
}

private extension View {
    /// The design's row spacing: 11 points above and below, so an icon row is 56 points.
    func settingsRow() -> some View {
        listRowInsets(.vertical, 11)
    }
}

/// A section's name above its card: small, bold, uppercase and gray.
private struct SettingsHeader: View {
    let text: LocalizedStringResource

    init(_ text: LocalizedStringResource) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .font(.theme(.footnote))
            .fontWeight(.bold)
            .tracking(0.6)
            .foregroundStyle(.theme(.textTertiary))
    }
}

/// What a section does, under its card: small and gray.
private struct SettingsFooter: View {
    let text: LocalizedStringResource

    init(_ text: LocalizedStringResource) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.theme(.caption))
            .lineSpacing(2)
            .foregroundStyle(.theme(.textTertiary))
    }
}

#if DEBUG
    #Preview {
        SettingsView(
            scheduler: NotificationReminderScheduler { nil },
            lock: AppLockViewModel(
                settings: LockSettings(defaults: .standard),
                authenticator: LocalDeviceAuthenticator(),
            ),
        )
        .modelContainer(AppModelContainer.preview)
    }
#endif
