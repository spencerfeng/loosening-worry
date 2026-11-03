/// The suggested reminder times on onboarding's last screen.
enum ReminderPreset: CaseIterable {
    case morning, midday, evening

    var time: ReminderTime {
        switch self {
        case .morning: ReminderTime(hour: 8, minute: 0)
        case .midday: ReminderTime(hour: 12, minute: 30)
        case .evening: .eightPM
        }
    }
}
