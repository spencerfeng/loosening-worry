import SwiftUI

/// The Check-ins side of Insights: how the check-ins felt, the words named most, and what weighs on the person and what
/// lifts them, once there are enough to mean something.
struct CheckInInsights: View {
    let report: CheckInReport

    var body: some View {
        if report.hasEnough {
            FeltCard(report: report)
            if !report.namedFeelings.isEmpty {
                NamedFeelingsCard(named: report.namedFeelings)
            }
            if !report.weighs.isEmpty || !report.lifts.isEmpty {
                WeighsAndLiftsCard(weighs: report.weighs, lifts: report.lifts)
            }
        } else {
            InsightsCard(title: LocalizedStringResource("insights.checkIns", defaultValue: "Check-ins")) {
                Text(LocalizedStringResource(
                    "insights.checkIns.wait",
                    defaultValue: "After a few more check-ins, you'll see patterns here.",
                ))
                .font(.theme(.body))
                .foregroundStyle(.theme(.textSecondary))
                Text(report.totalLine)
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.textTertiary))
            }
        }
    }
}

extension CheckInReport {
    /// "16 check-ins in the last 4 weeks", "1 check-in this week": a plural on the count, written by hand in the
    /// catalog.
    var totalLine: LocalizedStringResource {
        let span = String(localized: period.span)
        return LocalizedStringResource("insights.checkIns.total", defaultValue: "\(total) check-ins \(span)")
    }
}

extension CheckInReport.ContextShare {
    /// "3 of 7 check-ins", "1 of 1 check-in": a plural on the total, written by hand in the catalog.
    var line: LocalizedStringResource {
        let (count, total) = (share.count, share.total)
        return LocalizedStringResource("insights.checkIns.share", defaultValue: "\(count) of \(total) check-ins")
    }
}

private extension Pleasantness.Side {
    /// The check-in's own hues for each side: violet, gray and amber, as on its first step. These fill shapes, so they
    /// use fill roles (ADR 0005, 0007); violet has none, as its strong shade already suits a fill.
    var color: Theme.ColorRole {
        switch self {
        case .unpleasant: .violetStrong
        case .neutral: .grayFill
        case .pleasant: .amberFill
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .unpleasant: LocalizedStringResource("insights.checkIns.unpleasant", defaultValue: "Unpleasant")
        case .neutral: LocalizedStringResource("insights.checkIns.neutral", defaultValue: "Neutral")
        case .pleasant: LocalizedStringResource("insights.checkIns.pleasant", defaultValue: "Pleasant")
        }
    }
}

/// How the check-ins felt: one bar split by side, each side's count, and the total. A mix, not a score.
private struct FeltCard: View {
    let report: CheckInReport

    var body: some View {
        let sides = report.felt.bySide
        InsightsCard(title: LocalizedStringResource(
            "insights.checkIns.felt",
            defaultValue: "How your check-ins felt",
        )) {
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    ForEach(sides, id: \.side) { side, count in
                        Rectangle()
                            .fill(.theme(side.color))
                            .frame(width: proxy.size.width * Share(count: count, total: report.total).fraction)
                    }
                }
            }
            .frame(height: 14)
            .clipShape(.capsule)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(sides, id: \.side) { side, count in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.theme(side.color))
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                        Text(side.name)
                            .foregroundStyle(.theme(.textPrimary))
                        Spacer()
                        Text(count, format: .number)
                            .fontWeight(.bold)
                            .foregroundStyle(.theme(.textPrimary))
                    }
                    .font(.theme(.body))
                    .accessibilityElement(children: .combine)
                }
            }
            Text(report.totalLine)
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.textSecondary))
        }
    }
}

/// The words named most, each with its count.
private struct NamedFeelingsCard: View {
    let named: [CheckInReport.NamedFeeling]

    var body: some View {
        InsightsCard(title: LocalizedStringResource(
            "insights.checkIns.named",
            defaultValue: "The feelings you name most",
        )) {
            FlowLayout(spacing: 8) {
                ForEach(named, id: \.feeling) { word in
                    HStack(spacing: 8) {
                        Text(word.feeling.label)
                            .fontWeight(.semibold)
                        Text(word.count, format: .number)
                            .fontWeight(.heavy)
                    }
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textPrimary))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 36)
                    .background(.theme(.surfaceSunken), in: .capsule)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

/// The contexts picked most on unpleasant check-ins and on pleasant ones, each out of that side's check-ins.
private struct WeighsAndLiftsCard: View {
    let weighs: [CheckInReport.ContextShare]
    let lifts: [CheckInReport.ContextShare]

    var body: some View {
        InsightsCard(title: LocalizedStringResource(
            "insights.checkIns.weighs",
            defaultValue: "What weighs on you, what lifts you",
        ), subtitle: LocalizedStringResource(
            "insights.checkIns.weighs.hint",
            defaultValue: "What you picked, by how you felt",
        )) {
            if !weighs.isEmpty {
                group(Self.onUnpleasant, side: .unpleasant, shares: weighs)
            }
            if !lifts.isEmpty {
                group(Self.onPleasant, side: .pleasant, shares: lifts)
            }
            Text(LocalizedStringResource(
                "insights.checkIns.weighs.note",
                defaultValue: "Neutral check-ins aren't counted here.",
            ))
            .font(.theme(.caption))
            .foregroundStyle(.theme(.textTertiary))
        }
    }

    private static let onUnpleasant = LocalizedStringResource(
        "insights.checkIns.onUnpleasant",
        defaultValue: "On unpleasant check-ins",
    )

    private static let onPleasant = LocalizedStringResource(
        "insights.checkIns.onPleasant",
        defaultValue: "On pleasant check-ins",
    )

    private func group(
        _ title: LocalizedStringResource,
        side: Pleasantness.Side,
        shares: [CheckInReport.ContextShare],
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(.theme(side.color))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.theme(.footnote))
                    .foregroundStyle(.theme(.textTertiary))
                    .accessibilityAddTraits(.isHeader)
            }
            ForEach(shares, id: \.id) { context in
                VStack(alignment: .leading, spacing: 6) {
                    // Side by side, or stacked when they don't fit, as on a trigger's page.
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text(verbatim: context.label).foregroundStyle(.theme(.textPrimary))
                            Spacer()
                            Text(context.line).foregroundStyle(.theme(.textTertiary))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: context.label).foregroundStyle(.theme(.textPrimary))
                            Text(context.line).foregroundStyle(.theme(.textTertiary))
                        }
                    }
                    .font(.theme(.callout))
                    Capsule()
                        .fill(.theme(.surfaceSunken))
                        .frame(height: 8)
                        .overlay(alignment: .leading) {
                            GeometryReader { proxy in
                                Capsule()
                                    .fill(.theme(side.color))
                                    .frame(width: proxy.size.width * context.share.fraction)
                            }
                        }
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
