import SwiftUI

/// "What sets you off": each trigger in the period, with a bar of what followed it, the habit in red and a tool in
/// green, and one line about it. A row opens the trigger's page.
struct WhatSetsYouOffCard: View {
    let rows: [TriggerSummary]
    let open: (String) -> Void

    var body: some View {
        InsightsCard(title: LocalizedStringResource("insights.setsYouOff", defaultValue: "What sets you off")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringResource("insights.setsYouOff.detail", defaultValue: "And what you did about it"))
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.textTertiary))
                ColorKey(entries: [
                    (.redFill, LocalizedStringResource("insights.key.habit", defaultValue: "The old habit")),
                    (.greenFill, LocalizedStringResource("insights.key.tool", defaultValue: "Met it with a tool")),
                ])
            }
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Divider()
                    }
                    Button {
                        open(row.id)
                    } label: {
                        TriggerSummaryRow(row: row)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// One trigger on the card: its name, the bar, the line, and a chevron to its page. VoiceOver reads the name and the
/// line, with the loop count as the value.
private struct TriggerSummaryRow: View {
    let row: TriggerSummary

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: row.label)
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textPrimary))
                SplitBar(habits: row.habits, tools: row.metWithTool)
                Text(row.line.sentence)
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.textSecondary))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.theme(.textTertiary))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(loopCount(row.habits + row.metWithTool)))
    }
}

extension TriggerSummary.Line {
    /// The row's line. "times" is a plural on the last number, written by hand in the catalog.
    var sentence: LocalizedStringResource {
        switch self {
        case let .metWithTool(met, total):
            LocalizedStringResource(
                "insights.setsYouOff.met",
                defaultValue: "Met it with a tool \(met) of \(total) times",
            )
        case let .habit(label, count):
            LocalizedStringResource("insights.setsYouOff.habit", defaultValue: "\(label) \(count) times")
        }
    }
}

/// What followed a trigger, as one bar: the habit in red, then a tool in green.
struct SplitBar: View {
    let habits: Int
    let tools: Int
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let total = max(habits + tools, 1)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.theme(.redFill))
                    .frame(width: proxy.size.width * Double(habits) / Double(total))
                Rectangle()
                    .fill(.theme(.greenFill))
            }
            .clipShape(.capsule)
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A key to a chart's colors: a swatch and its words for each. Side by side, or stacked at accessibility sizes so the
/// words aren't broken. VoiceOver skips it, since the chart's own words say the same.
private struct ColorKey: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let entries: [(Theme.ColorRole, LocalizedStringResource)]

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                HStack(spacing: 5) {
                    Circle().fill(.theme(entry.0)).frame(width: 8, height: 8)
                    Text(entry.1)
                        .font(.theme(.caption))
                        .foregroundStyle(.theme(.textTertiary))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// One trigger's page: what followed it in the period, what each way gave the person, when they noticed the habit,
/// and their own words.
struct TriggerDetailView: View {
    let detail: TriggerDetail
    let period: InsightsPeriod

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: detail.label)
                        .font(.theme(.title))
                        .foregroundStyle(.theme(.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                    Text(detail.totalLine(in: period))
                        .font(.theme(.callout))
                        .foregroundStyle(.theme(.textTertiary))
                }
                FollowedCard(detail: detail)
                if detail.habitsNoBetter != nil || detail.toolsLighter != nil {
                    GaveCard(detail: detail)
                }
                if !detail.noticed.isEmpty {
                    NoticedCard(detail: detail)
                }
                if !detail.notes.isEmpty {
                    NotesCard(notes: detail.notes)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(.theme(.background))
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension TriggerDetail {
    /// "6 times this week": plurals written by hand in the catalog.
    func totalLine(in period: InsightsPeriod) -> LocalizedStringResource {
        switch period {
        case .thisWeek:
            LocalizedStringResource("insights.trigger.thisWeek", defaultValue: "\(total) times this week")
        case .lastFourWeeks:
            LocalizedStringResource("insights.trigger.fourWeeks", defaultValue: "\(total) times in the last 4 weeks")
        }
    }

    /// "As it started 3 of the last 8 times". "times" is a plural on the last number, written by hand in the catalog.
    var noticedLine: LocalizedStringResource {
        let asItStarted = noticed.count { $0 == .asItStarted }
        return LocalizedStringResource(
            "insights.trigger.asItStarted",
            defaultValue: "As it started \(asItStarted) of the last \(noticed.count) times",
        )
    }
}

extension InsightsReport.Share {
    /// "no better 5 of 6 times", for the habits. "times" is a plural on the total, written by hand in the catalog.
    var noBetterLine: LocalizedStringResource {
        LocalizedStringResource("insights.trigger.noBetter", defaultValue: "no better \(count) of \(total) times")
    }

    /// "lighter 3 of 4 times", for the tools. "times" is a plural on the total, written by hand in the catalog.
    var lighterLine: LocalizedStringResource {
        LocalizedStringResource("insights.trigger.lighter", defaultValue: "lighter \(count) of \(total) times")
    }
}

/// "What you did": the bar, then each habit and tool that followed the trigger, most first, with its count.
private struct FollowedCard: View {
    let detail: TriggerDetail

    var body: some View {
        InsightsCard(title: LocalizedStringResource("insights.trigger.did", defaultValue: "What you did")) {
            SplitBar(habits: detail.habits, tools: detail.metWithTool, height: 12)
            ForEach(Array(detail.followedBy.enumerated()), id: \.offset) { _, followed in
                HStack(spacing: 8) {
                    Circle()
                        .fill(.theme(followed.isTool ? .greenFill : .redFill))
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(verbatim: followed.label)
                        .foregroundStyle(.theme(.textPrimary))
                    Spacer()
                    Text(followed.count, format: .number)
                        .foregroundStyle(.theme(.textSecondary))
                }
                .font(.theme(.body))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// The old way and the new way: how often the habits left the person no better, and the tools lighter.
private struct GaveCard: View {
    let detail: TriggerDetail

    var body: some View {
        InsightsCard(title: LocalizedStringResource("insights.trigger.gave", defaultValue: "What it gave you")) {
            if let share = detail.habitsNoBetter {
                ShareRow(
                    name: LocalizedStringResource("insights.trigger.habits", defaultValue: "Your habits"),
                    line: share.noBetterLine,
                    share: share,
                    color: .redFill,
                )
            }
            if let share = detail.toolsLighter {
                ShareRow(
                    name: LocalizedStringResource("insights.trigger.tools", defaultValue: "Meeting it with a tool"),
                    line: share.lighterLine,
                    share: share,
                    color: .greenFill,
                )
            }
        }
    }
}

/// A way of meeting the trigger, how it went in words, and a bar of the same share. The name and the words sit side
/// by side, or stacked when they don't fit.
private struct ShareRow: View {
    let name: LocalizedStringResource
    let line: LocalizedStringResource
    let share: InsightsReport.Share
    let color: Theme.ColorRole

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(name).foregroundStyle(.theme(.textPrimary))
                    Spacer()
                    Text(line).foregroundStyle(.theme(.textSecondary))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).foregroundStyle(.theme(.textPrimary))
                    Text(line).foregroundStyle(.theme(.textSecondary))
                }
            }
            .font(.theme(.callout))
            Capsule()
                .fill(.theme(.surfaceSunken))
                .frame(height: 10)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(.theme(color))
                            .frame(width: proxy.size.width * Double(share.count) / Double(max(share.total, 1)))
                    }
                }
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// When the person noticed the habit, oldest first: gray afterwards, pale blue partway, blue as it started. VoiceOver
/// reads the answers in order, so the trend is there without the colors.
private struct NoticedCard: View {
    let detail: TriggerDetail

    var body: some View {
        InsightsCard(title: LocalizedStringResource(
            "insights.trigger.noticed",
            defaultValue: "When you noticed the habit",
        )) {
            HStack(spacing: 8) {
                ForEach(Array(detail.noticed.enumerated()), id: \.offset) { _, timing in
                    Circle()
                        .fill(.theme(Self.color(timing)))
                        .frame(width: 24, height: 24)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizedStringResource(
                "insights.trigger.noticedOrder",
                defaultValue: "Oldest first: \(answersInOrder)",
            )))
            Text(detail.noticedLine)
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.textSecondary))
            ColorKey(entries: NoticeTiming.allCases.map { (Self.color($0), $0.label) })
        }
    }

    /// "afterwards, partway through and as it started", in the person's language.
    private var answersInOrder: String {
        detail.noticed.map { String(localized: $0.label) }.formatted(.list(type: .and))
    }

    private static func color(_ timing: NoticeTiming) -> Theme.ColorRole {
        switch timing {
        case .afterwards: .grayFill
        case .partway: .accentPaleFill
        case .asItStarted: .accent
        }
    }
}

/// "In your words": the person's latest notes after this trigger, each with the loop it was about and its day.
private struct NotesCard: View {
    let notes: [TriggerDetail.Note]

    var body: some View {
        InsightsCard(title: LocalizedStringResource("insights.trigger.words", defaultValue: "In your words")) {
            ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "\u{201C}\(note.text)\u{201D}")
                        .font(.theme(.headline))
                        .foregroundStyle(.theme(.textPrimary))
                    Text(verbatim: [
                        note.behavior,
                        note.result,
                        note.date.formatted(.dateTime.weekday(.wide).day().month()),
                    ].joined(separator: " · "))
                        .font(.theme(.footnote))
                        .foregroundStyle(.theme(.textTertiary))
                }
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle().fill(.theme(.border)).frame(width: 3)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
