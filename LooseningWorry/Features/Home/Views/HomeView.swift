import SwiftData
import SwiftUI

/// Home: a greeting, a way into the logger, today's lesson, the quick tools and a line about the week.
struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var loops: [Loop]
    @Query private var sessions: [ToolSession]
    @Query private var lessonProgress: [LessonProgress]

    /// Opens the logger, other tabs, lessons, tools, Settings and Help.
    let root: RootViewModel

    var body: some View {
        // Redrawn each minute, so the date, the greeting and the week roll over while Home stays open.
        TimelineView(.everyMinute) { context in
            content(now: context.date)
        }
        .background(.theme(.background))
    }

    @ViewBuilder private var headerButtons: some View {
        SettingsButton { root.openSettings() }
        HelpButton { root.openHelp() }
    }

    private func content(now: Date) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // At accessibility sizes the greeting needs the full width, so Settings and Help move above it.
                if dynamicTypeSize.isAccessibilitySize {
                    HStack(spacing: 8) { headerButtons }
                    HomeHeader(now: now)
                } else {
                    HStack(alignment: .center, spacing: 12) {
                        HomeHeader(now: now)
                        Spacer(minLength: 0)
                        HStack(spacing: 8) { headerButtons }
                    }
                }
                LogBanner { root.select(.log) }
                if let card = HomeContent.nextLesson(progress: lessonProgress, catalog: .bundled) {
                    Text(LocalizedStringResource("home.forYou", defaultValue: "For you today"))
                        .font(.theme(.title3))
                        .foregroundStyle(.theme(.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, -6)
                    NextLessonCard(card: card) { root.openLesson(card.lesson) }
                }
                QuickToolsGrid { root.openTool($0) }
                // Counted up to the actual time, not the timeline's minute, which can be up to a minute behind: a
                // loop or tool saved since that minute began would otherwise be left out until the next one.
                WeekLine(week: HomeContent.thisWeek(loops: loops, sessions: sessions, now: .now, calendar: .current)) {
                    root.select(.insights)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

private struct HomeHeader: View {
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.textTertiary))
            Text(greeting)
                .font(.theme(.title))
                .foregroundStyle(.theme(.textPrimary))
                .accessibilityAddTraits(.isHeader)
        }
        .accessibilityElement(children: .combine)
    }

    private var greeting: LocalizedStringResource {
        switch HomeContent.greeting(at: now, calendar: .current) {
        case .morning: LocalizedStringResource("home.greeting.morning", defaultValue: "Good morning")
        case .afternoon: LocalizedStringResource("home.greeting.afternoon", defaultValue: "Good afternoon")
        case .evening: LocalizedStringResource("home.greeting.evening", defaultValue: "Good evening")
        }
    }
}

/// Opens Settings: an icon-only round gear, named for VoiceOver.
private struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.theme(.callout))
                .fontWeight(.semibold)
                .foregroundStyle(.theme(.textSecondary))
                // Padding rather than a fixed size, so the circle grows with the gear at large text sizes.
                .padding(11)
                .frame(minWidth: 44, minHeight: 44)
                .background(.theme(.surface), in: .circle)
                .overlay { Circle().strokeBorder(.theme(.border)) }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringResource("home.settings", defaultValue: "Settings")))
    }
}

/// Opens Help, the crisis path, in its own color (ADR 0001).
private struct HelpButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "lifepreserver")
                    .fontWeight(.semibold)
                    .foregroundStyle(.theme(.help))
                    .accessibilityHidden(true)
                Text(LocalizedStringResource("home.help", defaultValue: "Help"))
                    .foregroundStyle(.theme(.textPrimary))
            }
            .font(.theme(.callout))
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .frame(minHeight: 44)
            .background(.theme(.surface), in: .capsule)
            .overlay { Capsule().strokeBorder(.theme(.border)) }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(LocalizedStringResource("home.help.hint", defaultValue: "Crisis lines and support")))
    }
}

/// "Feeling it now?": the quickest way into the logger from Home.
private struct LogBanner: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let action: () -> Void

    var body: some View {
        // At the largest text sizes the button moves under the words, so neither gets squeezed.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringResource("home.banner.title", defaultValue: "Feeling it now?"))
                    .font(.theme(.headline))
                Text(LocalizedStringResource(
                    "home.banner.detail",
                    defaultValue: "Log trigger, behavior, result in 20 sec",
                ))
                .font(.theme(.caption))
            }
            .foregroundStyle(.theme(.textOnAccent))
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                        .fontWeight(.semibold)
                        .accessibilityHidden(true)
                    Text("Log a loop")
                }
                .font(.theme(.callout))
                .foregroundStyle(.theme(.accentText))
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .frame(minHeight: 44)
                .background(.theme(.surface), in: .capsule)
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                .contentShape(.capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .background(.theme(.accent), in: .rect(cornerRadius: 20))
    }
}

/// The four tools; each tile starts its tool.
private struct QuickToolsGrid: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let start: (QuickTool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringResource("home.tools.title", defaultValue: "Quick tools"))
                    .font(.theme(.title3))
                    .foregroundStyle(.theme(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
                Text(LocalizedStringResource("home.tools.detail", defaultValue: "Use one anytime worry shows up"))
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textTertiary))
            }
            // One column at the largest text sizes, so the names aren't cut off.
            let columnCount = dynamicTypeSize.isAccessibilitySize ? 1 : 2
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount), spacing: 10) {
                ForEach(QuickTool.allCases) { tool in
                    ToolTile(tool: tool) { start(tool) }
                }
            }
        }
    }
}

private struct ToolTile: View {
    let tool: QuickTool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
        HStack(spacing: 10) {
            Image(systemName: tool.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.theme(tool.ink))
                .frame(width: 36, height: 36)
                .background(.theme(tool.tint), in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)
            Text(tool.name)
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.textPrimary))
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(minHeight: 58)
        .background(.theme(.surface), in: .rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.theme(.borderSubtle)) }
        .contentShape(.rect(cornerRadius: 18))
    }
}

/// "This week: 9 loops noticed · 6 tools used". Opens Insights.
private struct WeekLine: View {
    let week: HomeContent.WeekSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(sentence)
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textSecondary))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.theme(.textTertiary))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(LocalizedStringResource("home.week.hint", defaultValue: "Opens Insights")))
    }

    /// The counts are the strong run, so translators keep them together and in the right place.
    private var sentence: AttributedString {
        let loops = String(localized: LocalizedStringResource(
            "home.week.loops",
            defaultValue: "\(week.loops) loops noticed",
        ))
        let tools = String(localized: LocalizedStringResource(
            "home.week.tools",
            defaultValue: "\(week.tools) tools used",
        ))
        return AttributedString(localized: LocalizedStringResource(
            "home.week",
            defaultValue: "This week: **\(loops) · \(tools)**",
        ))
        .restylingEmphasis(font: .theme(.callout), color: .theme(.textPrimary))
    }
}

#if DEBUG
    #Preview {
        HomeView(root: RootViewModel())
            .modelContainer(AppModelContainer.preview)
    }
#endif
