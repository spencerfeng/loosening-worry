import Charts
import SwiftData
import SwiftUI

/// Insights: how many loops the person noticed and when, what sets them off most, and what the habit they reach for
/// most actually gives them; or, switched to check-ins, how those felt. For this week or the last four. Each card
/// shows as soon as it means something.
struct InsightsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Only the loops the longest period can show, so the work stays small as history grows.
    @Query private var loops: [Loop]
    @Query private var savedOptions: [LoopOption]
    /// Whether anything has ever been logged, for the right words when the period is empty.
    @Query private var anyLoop: [Loop]
    /// Only the check-ins the longest period can show, like `loops`.
    @Query private var checkIns: [CheckIn]
    /// Back to this week on each visit.
    @State private var period = InsightsPeriod.thisWeek
    /// Back to loops on each visit.
    @State private var subject = InsightsSubject.loops
    /// The trigger whose page is open, by the id `InsightsReport.triggers` gives it.
    @State private var openTrigger: String?

    /// Opens the logger, from the card shown before anything's logged.
    let logLoop: () -> Void

    init(logLoop: @escaping () -> Void) {
        self.logLoop = logLoop
        let start = InsightsPeriod.lastFourWeeks.start(now: .now, calendar: .current) ?? .distantPast
        _loops = Query(filter: #Predicate<Loop> { $0.createdAt >= start })
        var anyLoop = FetchDescriptor<Loop>()
        anyLoop.fetchLimit = 1
        _anyLoop = Query(anyLoop)
        _checkIns = Query(filter: #Predicate<CheckIn> { $0.createdAt >= start })
    }

    var body: some View {
        NavigationStack {
            content
                .toolbarVisibility(.hidden, for: .navigationBar)
        }
        // A visit starts afresh: this week, and no trigger's page left open for a period it no longer matches.
        .onDisappear {
            period = .thisWeek
            subject = .loops
            openTrigger = nil
        }
    }

    private var content: some View {
        // Redrawn each minute, so today and this week move on while Insights stays open; counted up to the actual
        // time, so a loop just logged shows straight away. A trigger's page is built here too, so it moves on with
        // the card.
        TimelineView(.everyMinute) { _ in
            let report = InsightsReport(
                loops: loops,
                saved: savedOptions,
                period: period,
                now: .now,
                calendar: .current,
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    Picker(selection: $subject) {
                        Text(LocalizedStringResource("insights.show.loops", defaultValue: "Loops"))
                            .tag(InsightsSubject.loops)
                        Text(LocalizedStringResource("insights.show.checkIns", defaultValue: "Check-ins"))
                            .tag(InsightsSubject.checkIns)
                    } label: {
                        Text(LocalizedStringResource("insights.show", defaultValue: "Show insights for"))
                    }
                    .pickerStyle(.segmented)
                    if subject == .checkIns {
                        CheckInInsights(
                            report: CheckInReport(
                                checkIns: checkIns,
                                saved: savedOptions,
                                period: period,
                                now: .now,
                                calendar: .current,
                            )
                        )
                    } else if report.isEmpty {
                        NothingYetCard(period: period, isFirstTime: anyLoop.isEmpty, logLoop: logLoop)
                    } else {
                        LoopsCard(report: report)
                        WhatSetsYouOffCard(rows: report.triggers) { openTrigger = $0 }
                        if let habit = report.habit {
                            HabitCard(habit: habit, period: period)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationDestination(item: $openTrigger) { id in
                if let detail = report.trigger(id) {
                    TriggerDetailView(detail: detail, period: period)
                }
            }
        }
        .background(.theme(.background))
    }

    /// The title and the period, side by side, or stacked at accessibility sizes so the title isn't broken.
    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout())
        return layout {
            Text(LocalizedStringResource("insights.title", defaultValue: "Insights"))
                .font(.theme(.title))
                .foregroundStyle(.theme(.textPrimary))
                .accessibilityAddTraits(.isHeader)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            Menu {
                Picker(selection: $period) {
                    ForEach(InsightsPeriod.allCases, id: \.self) { period in
                        Text(period.name).tag(period)
                    }
                } label: {
                    Text(LocalizedStringResource("insights.period", defaultValue: "Period"))
                }
            } label: {
                HStack(spacing: 6) {
                    Text(period.name)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .accessibilityHidden(true)
                }
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.textPrimary))
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(.theme(.surface), in: .capsule)
                .overlay { Capsule().strokeBorder(.theme(.border)) }
            }
            .accessibilityLabel(Text(LocalizedStringResource("insights.period", defaultValue: "Period")))
            .accessibilityValue(Text(period.name))
        }
    }
}

/// What Insights is showing: the person's loops, or their check-ins.
enum InsightsSubject {
    case loops, checkIns
}

extension InsightsPeriod {
    /// "This week", "Last 4 weeks"
    var name: LocalizedStringResource {
        switch self {
        case .thisWeek: LocalizedStringResource("insights.period.thisWeek", defaultValue: "This week")
        case .lastFourWeeks: LocalizedStringResource("insights.period.lastFourWeeks", defaultValue: "Last 4 weeks")
        }
    }

    /// How the period is said after a count: "this week", "in the last 4 weeks"
    var span: LocalizedStringResource {
        switch self {
        case .thisWeek: LocalizedStringResource("insights.span.thisWeek", defaultValue: "this week")
        case .lastFourWeeks: LocalizedStringResource("insights.span.lastFourWeeks", defaultValue: "in the last 4 weeks")
        }
    }
}

/// "2 loops", a plural in the catalog.
func loopCount(_ count: Int) -> LocalizedStringResource {
    LocalizedStringResource("insights.loopCount", defaultValue: "\(count) loops")
}

/// The loops noticed in the period, a bar for each day or week, and when loops tend to start.
private struct LoopsCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let report: InsightsReport

    var body: some View {
        InsightsCard(title: LocalizedStringResource("insights.loops", defaultValue: "Loops noticed")) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(report.total, format: .number)
                    .font(.theme(.largeTitle))
                    .foregroundStyle(.theme(.textPrimary))
                Text(report.period.span)
                    .font(.theme(.callout))
                    .foregroundStyle(.theme(.textTertiary))
            }
            .accessibilityElement(children: .combine)
            // Bars are placed by their dates, so labels that look alike ("T" for Tuesday and Thursday) stay apart.
            Chart(report.bars, id: \.start) { bar in
                BarMark(
                    x: .value(
                        Text(LocalizedStringResource("insights.chart.when", defaultValue: "When")),
                        bar.start,
                        unit: report.period.unit,
                    ),
                    y: .value(Text(LocalizedStringResource("insights.chart.loops", defaultValue: "Loops")), bar.count),
                )
                .foregroundStyle(.theme(bar.isCurrent ? .accent : .accentBorder))
                .clipShape(.rect(cornerRadius: 6))
                .accessibilityLabel(accessibilityName(for: bar))
                .accessibilityValue(Text(loopCount(bar.count)))
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: report.bars.map(\.start)) { value in
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            Text(verbatim: label(for: date))
                        }
                    }
                    .font(.theme(.caption2))
                    .foregroundStyle(.theme(.textTertiary))
                }
            }
            // Labels under narrow bars: capped so they don't run into each other; VoiceOver reads each bar in full.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .frame(height: 120)
            if let window = report.busiestWindow {
                let from = window.start.formatted(.dateTime.hour())
                let to = window.end.formatted(.dateTime.hour())
                Text(LocalizedStringResource(
                    "insights.busiest",
                    defaultValue: "Most loops start between \(from) and \(to).",
                ))
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.textSecondary))
            }
        }
    }

    /// "Mon" for a day ("M" at accessibility sizes, so seven fit), "5 Oct" for a week.
    private func label(for start: Date) -> String {
        switch report.period {
        case .thisWeek:
            start.formatted(.dateTime.weekday(dynamicTypeSize.isAccessibilitySize ? .narrow : .abbreviated))
        case .lastFourWeeks:
            start.formatted(.dateTime.day().month(.abbreviated))
        }
    }

    /// "Monday, today", "Week of 5 October"
    private func accessibilityName(for bar: InsightsReport.Bar) -> Text {
        let name: String = switch report.period {
        case .thisWeek:
            bar.start.formatted(.dateTime.weekday(.wide))
        case .lastFourWeeks:
            String(localized: LocalizedStringResource(
                "insights.weekOf",
                defaultValue: "Week of \(bar.start.formatted(.dateTime.day().month(.wide)))",
            ))
        }
        guard bar.isCurrent else { return Text(verbatim: name) }
        let current = report.period == .thisWeek
            ? LocalizedStringResource("insights.today", defaultValue: "today")
            : LocalizedStringResource("insights.thisWeek", defaultValue: "this week")
        return Text(verbatim: "\(name), \(String(localized: current))")
    }
}

/// What the habit logged most gave the person: a ring of the times it brought more worry, tension or no change.
/// Until there are three loops with a clear result, it says more loops will tell.
private struct HabitCard: View {
    let habit: InsightsReport.Habit
    let period: InsightsPeriod

    var body: some View {
        InsightsCard {
            HStack(spacing: 16) {
                if habit.hasEnough {
                    ring
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringResource(
                        "insights.habit.title",
                        defaultValue: "What \u{201C}\(habit.label)\u{201D} gave you",
                    ))
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textPrimary))
                    Text(detail)
                        .font(.theme(.subheadline))
                        .foregroundStyle(.theme(.textSecondary))
                        .lineSpacing(2)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var detail: LocalizedStringResource {
        guard habit.hasEnough else {
            return LocalizedStringResource(
                "insights.habit.wait",
                defaultValue: "After a few more loops, you'll see what each habit gives you.",
            )
        }
        let span = String(localized: period.span)
        let (unrewarding, total) = (habit.unrewarding, habit.total)
        return LocalizedStringResource(
            "insights.habit.detail",
            defaultValue: "\(unrewarding) of \(total) times \(span), it brought more worry, tension, or no change.",
        )
    }

    /// "7/9", filling with the times it didn't pay off.
    private var ring: some View {
        ZStack {
            Circle()
                .stroke(.theme(.border), lineWidth: 6)
            Circle()
                .trim(from: 0, to: Double(habit.unrewarding) / Double(max(habit.total, 1)))
                .stroke(.theme(.greenFill), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(verbatim: "\(habit.unrewarding)/\(habit.total)")
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.greenStrong))
        }
        .frame(width: 64, height: 64)
        .accessibilityHidden(true)
    }
}

/// When nothing's logged in the period: for someone new, what will show here; for someone back after a quiet spell,
/// simply that the period has nothing yet. Either way, the way to log a loop.
private struct NothingYetCard: View {
    let period: InsightsPeriod
    let isFirstTime: Bool
    let logLoop: () -> Void

    var body: some View {
        InsightsCard(title: LocalizedStringResource("insights.loops", defaultValue: "Loops noticed")) {
            Text(message)
                .font(.theme(.body))
                .foregroundStyle(.theme(.textSecondary))
                .lineSpacing(3)
            Button(action: logLoop) {
                Text(LocalizedStringResource("insights.logLoop", defaultValue: "Log a loop"))
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textOnAccent))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(.theme(.accent), in: .capsule)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
        }
    }

    private var message: LocalizedStringResource {
        let span = String(localized: period.span)
        guard isFirstTime else {
            return LocalizedStringResource("insights.empty.quiet", defaultValue: "No loops noticed \(span) yet.")
        }
        return LocalizedStringResource(
            "insights.empty",
            defaultValue: """
            Each loop you notice shows up here: when they start, what sets them off, and what your habits give you.
            """,
        )
    }
}

/// A card on the surface color, with a small title when it has one, and a line under the title that says what the
/// card shows, set close to it.
struct InsightsCard<Content: View>: View {
    var title: LocalizedStringResource?
    var subtitle: LocalizedStringResource?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.theme(.callout))
                        .foregroundStyle(.theme(.textSecondary))
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .font(.theme(.caption))
                            .foregroundStyle(.theme(.textTertiary))
                    }
                }
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 22)
    }
}

#if DEBUG
    #Preview {
        InsightsView {}
            .modelContainer(AppModelContainer.preview)
    }
#endif
