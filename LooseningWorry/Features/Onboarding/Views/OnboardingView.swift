import SwiftUI

/// The five screens a new device opens on. Each is a picture panel, a title and one line; the dots and the button stay
/// put below while the screens swipe. There's no Skip: the screen about Help is one everyone should see once.
struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: OnboardingViewModel

    init(settings: ReminderSettings, scheduler: any ReminderScheduler, finish: @escaping () -> Void) {
        _model = State(initialValue: OnboardingViewModel(settings: settings, scheduler: scheduler, finish: finish))
    }

    var body: some View {
        TabView(selection: $model.step) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                OnboardingPage(step: step, model: model)
                    .tag(step)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 6) {
                PageDots(current: model.step)
                    .padding(.bottom, 18)
                if model.step == .checkIn {
                    PrimaryButton(title: LocalizedStringResource(
                        "onboarding.checkIn.turnOn",
                        defaultValue: "Turn on check-in",
                    )) {
                        Task { await model.turnOnCheckIn() }
                    }
                    .disabled(model.isTurningOn)
                    Button {
                        model.skipCheckIn()
                    } label: {
                        Text(LocalizedStringResource("onboarding.checkIn.notNow", defaultValue: "Not now"))
                            .font(.theme(.callout))
                            .foregroundStyle(.theme(.accentText))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isTurningOn)
                    Text(LocalizedStringResource(
                        "onboarding.checkIn.note",
                        defaultValue: "Change it anytime in Settings.",
                    ))
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textTertiary))
                } else {
                    PrimaryButton(title: model.step.continueTitle) {
                        withAnimation(reduceMotion ? nil : .easeInOut) { model.next() }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.theme(.background))
        }
        .background(.theme(.background))
    }
}

/// One screen: its picture panel, then its title and line. It scrolls when large text needs the room; at the largest
/// sizes the words come first, as the panel alone would fill the screen and push them under the button.
private struct OnboardingPage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let step: OnboardingStep
    let model: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if dynamicTypeSize.isAccessibilitySize {
                    titleAndLine
                    framedPanel
                } else {
                    framedPanel
                    titleAndLine
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var framedPanel: some View {
        panel
            .frame(maxWidth: .infinity, minHeight: 320)
            .padding(16)
            .background(.theme(.accentTint), in: .rect(cornerRadius: 32))
    }

    private var titleAndLine: some View {
        VStack(spacing: 10) {
            Text(step.title)
                .font(.theme(.title))
                .foregroundStyle(.theme(.textPrimary))
                .accessibilityAddTraits(.isHeader)
            Text(step.line)
                .font(.theme(.headline))
                .fontWeight(.regular)
                .foregroundStyle(.theme(.textSecondary))
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder private var panel: some View {
        switch step {
        case .welcome: WelcomeArt()
        case .loop: LoopArt()
        case .uses: UsesPanel()
        case .goodToKnow: GoodToKnowPanel()
        case .checkIn: CheckInPicker(model: model)
        }
    }
}

/// Where the person is among the five screens; the current one stretches into a pill.
private struct PageDots: View {
    let current: OnboardingStep

    var body: some View {
        let steps = OnboardingStep.allCases
        HStack(spacing: 8) {
            ForEach(steps, id: \.self) { step in
                Capsule()
                    .fill(.theme(step == current ? .accent : .border))
                    .frame(width: step == current ? 24 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .accessibilityElement()
        .accessibilityLabel(Text(LocalizedStringResource(
            "onboarding.step",
            defaultValue: "Step \((steps.firstIndex(of: current) ?? 0) + 1) of \(steps.count)",
        )))
    }
}

private struct PrimaryButton: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textOnAccent))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(.theme(.accent), in: .capsule)
                .shadow(color: .theme(.accentShadow), radius: 8, y: 6)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

/// Each screen's words. Draft copy; the Good to know screen needs the clinician's review before launch.
private extension OnboardingStep {
    var title: LocalizedStringResource {
        switch self {
        case .welcome: LocalizedStringResource("onboarding.welcome.title", defaultValue: "Worry, loosened")
        case .loop: LocalizedStringResource("onboarding.loop.title", defaultValue: "Worry runs in loops")
        case .uses: LocalizedStringResource("onboarding.uses.title", defaultValue: "When worry shows up")
        case .goodToKnow: LocalizedStringResource("onboarding.goodToKnow.title", defaultValue: "Good to know")
        case .checkIn: LocalizedStringResource("onboarding.checkIn.title", defaultValue: "Daily check-in")
        }
    }

    var line: LocalizedStringResource {
        switch self {
        case .welcome:
            LocalizedStringResource("onboarding.welcome.line", defaultValue: "Notice it. Get curious. Let it go.")
        case .loop:
            LocalizedStringResource("onboarding.loop.line", defaultValue: "Spot the loop, and it starts to loosen.")
        case .uses:
            LocalizedStringResource("onboarding.uses.line", defaultValue: "Plus a short lesson each day.")
        case .goodToKnow:
            LocalizedStringResource("onboarding.goodToKnow.line", defaultValue: "Two things before you start.")
        case .checkIn:
            LocalizedStringResource(
                "onboarding.checkIn.line",
                defaultValue: "When do you usually have a few minutes?",
            )
        }
    }

    var continueTitle: LocalizedStringResource {
        switch self {
        case .welcome: LocalizedStringResource("onboarding.getStarted", defaultValue: "Get started")
        case .goodToKnow: LocalizedStringResource("onboarding.gotIt", defaultValue: "Got it")
        case .loop, .uses, .checkIn: LocalizedStringResource("onboarding.continue", defaultValue: "Continue")
        }
    }
}

#if DEBUG
    #Preview {
        OnboardingView(settings: ReminderSettings(defaults: .standard), scheduler: PreviewScheduler()) {}
    }

    private struct PreviewScheduler: ReminderScheduler {
        func permissionStatus() async -> ReminderPermission {
            .allowed
        }

        func askPermission() async -> Bool {
            true
        }

        func scheduleDaily(at _: ReminderTime) async throws {}
        func cancel() {}
    }
#endif
