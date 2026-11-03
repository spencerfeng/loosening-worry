import SwiftUI

/// One segment per step of a flow: full once answered, partly filled while current. The flow's header already says
/// which step, so VoiceOver skips it.
struct StepProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let steps: [StepProgress]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                Capsule()
                    .fill(.theme(.border))
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.theme(.accentSoft), .theme(.accent)],
                                        startPoint: .leading,
                                        endPoint: .trailing,
                                    )
                                )
                                .frame(width: proxy.size.width * Self.fill(for: step))
                        }
                    }
                    .frame(height: 6)
            }
        }
        // A width change is movement even when slow, so under Reduce Motion the segments jump instead.
        .transaction { transaction in
            if transaction.animation != nil {
                transaction.animation = reduceMotion ? nil : .easeOut(duration: 0.3)
            }
        }
        .accessibilityHidden(true)
    }

    private static func fill(for step: StepProgress) -> CGFloat {
        switch step {
        case .answered, .reopened: 1
        case .current: 0.35
        case .upcoming: 0
        }
    }
}
