import SwiftUI

/// The check-in panel: three suggested times above a time wheel. Picking a suggestion turns the wheel to it; turning
/// the wheel to a time of the person's own leaves no suggestion picked.
struct CheckInPicker: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let model: OnboardingViewModel

    var body: some View {
        VStack(spacing: 10) {
            let presets = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 8))
                : AnyLayout(HStackLayout(spacing: 8))
            presets {
                ForEach(CheckInPreset.allCases, id: \.self) { preset in
                    PresetCard(preset: preset, isPicked: model.preset == preset) { model.pick(preset) }
                }
            }
            .sensoryFeedback(.selection, trigger: model.checkInTime)

            DatePicker(
                selection: Binding(
                    get: { model.checkInTime.date() },
                    set: { model.checkInTime = ReminderTime(date: $0) },
                ),
                displayedComponents: .hourAndMinute,
            ) {
                Text(LocalizedStringResource("onboarding.checkIn.time", defaultValue: "Check-in time"))
            }
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .background(.theme(.surface), in: .rect(cornerRadius: 20))
        }
    }
}

/// Morning, Midday or Evening: its icon on its loop color, its name and its time.
private struct PresetCard: View {
    let preset: CheckInPreset
    let isPicked: Bool
    let pick: () -> Void

    var body: some View {
        Button(action: pick) {
            VStack(spacing: 4) {
                Image(systemName: preset.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.theme(preset.fill), in: .circle)
                    .padding(.bottom, 2)
                    .accessibilityHidden(true)
                Text(preset.name)
                    .font(.theme(.callout))
                    .fontWeight(.heavy)
                Text(preset.time.date().formatted(date: .omitted, time: .shortened))
                    .font(.theme(.footnote))
                    .opacity(0.8)
            }
            .foregroundStyle(.theme(isPicked ? .textOnAccent : .textPrimary))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 112)
            .background(.theme(isPicked ? .accent : .surface), in: .rect(cornerRadius: 20))
            .shadow(color: isPicked ? .theme(.accentShadow) : .clear, radius: 8, y: 6)
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }
}

private extension CheckInPreset {
    var name: LocalizedStringResource {
        switch self {
        case .morning: LocalizedStringResource("onboarding.checkIn.morning", defaultValue: "Morning")
        case .midday: LocalizedStringResource("onboarding.checkIn.midday", defaultValue: "Midday")
        case .evening: LocalizedStringResource("onboarding.checkIn.evening", defaultValue: "Evening")
        }
    }

    var symbol: String {
        switch self {
        case .morning: "sunrise"
        case .midday: "sun.max"
        case .evening: "moon"
        }
    }

    /// The loop colors from onboarding's drawings.
    var fill: Theme.ColorRole {
        switch self {
        case .morning: .greenFill
        case .midday: .amberFill
        case .evening: .violetStrong
        }
    }
}
