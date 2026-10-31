import SwiftUI

/// The cover over a locked app: the icon, a line saying it's locked, and Unlock. While the app is only away, under
/// Control Center or in the app switcher, it shows just the icon, as there's nothing to unlock.
struct LockView: View {
    let lock: AppLockViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 22) {
                Image(.appMark)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .clipShape(.rect(cornerRadius: 21.5, style: .continuous))
                    .shadow(color: .black.opacity(0.14), radius: 12, y: 10)
                    .accessibilityHidden(true)
                if lock.isLocked {
                    VStack(spacing: 8) {
                        Text(LocalizedStringResource("lock.title", defaultValue: "Loosening Worry is locked"))
                            .font(.theme(.title2))
                            .foregroundStyle(.theme(.textPrimary))
                            .accessibilityAddTraits(.isHeader)
                        Text(LocalizedStringResource(
                            "lock.detail",
                            defaultValue: "Unlock to see your loops and lessons.",
                        ))
                        .font(.theme(.body))
                        .foregroundStyle(.theme(.textSecondary))
                    }
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
            if lock.isLocked {
                Button {
                    Task { await lock.unlock() }
                } label: {
                    Label {
                        Text(LocalizedStringResource("lock.unlock", defaultValue: "Unlock"))
                    } icon: {
                        Image(systemName: lock.method?.symbol ?? "lock.open")
                    }
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textOnAccent))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(.theme(.accent), in: .capsule)
                    .shadow(color: .theme(.accentShadow), radius: 8, y: 6)
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.theme(.background))
    }
}

/// How the lock is drawn, in Settings and on the cover.
extension LockMethod {
    var symbol: String {
        switch self {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        case .passcode: "lock"
        }
    }
}
