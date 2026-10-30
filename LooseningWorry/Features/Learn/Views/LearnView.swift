import SwiftData
import SwiftUI

/// Learn: the next lesson, then the whole course in its three stages, each lesson ticked once it's done. Any lesson
/// opens in the reader.
struct LearnView: View {
    @Query private var progress: [LessonProgress]

    let openLesson: (Lesson) -> Void

    var body: some View {
        let catalog = LessonCatalog.bundled
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringResource("learn.title", defaultValue: "Learn"))
                        .font(.theme(.title))
                        .foregroundStyle(.theme(.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                    Text(LocalizedStringResource("learn.subtitle", defaultValue: "30 days · 5 minutes a day"))
                        .font(.theme(.subheadline))
                        .foregroundStyle(.theme(.textTertiary))
                }
                if let next = HomeContent.nextLesson(progress: progress, catalog: catalog) {
                    NextLessonCard(card: next, heading: .upNext) { openLesson(next.lesson) }
                }
                ForEach(LearnContent.stages(progress: progress, catalog: catalog), id: \.number) { stage in
                    StageSection(stage: stage, openLesson: openLesson)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(.theme(.background))
    }
}

/// A stage's heading and its ten lessons.
private struct StageSection: View {
    let stage: LearnContent.Stage
    let openLesson: (Lesson) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.theme(.title3))
                    .foregroundStyle(.theme(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
                if let first = stage.rows.first?.lesson.day, let last = stage.rows.last?.lesson.day {
                    Text(LocalizedStringResource("learn.stage.days", defaultValue: "Days \(first)–\(last)"))
                        .font(.theme(.subheadline))
                        .foregroundStyle(.theme(.textTertiary))
                }
            }
            .padding(.top, 4)
            VStack(spacing: 0) {
                ForEach(stage.rows, id: \.lesson.day) { row in
                    LessonRow(row: row) { openLesson(row.lesson) }
                }
            }
            .padding(.vertical, 4)
            .background(.theme(.surface), in: .rect(cornerRadius: 22))
            .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(.theme(.borderSubtle)) }
        }
    }

    /// The outline's names for the three stages.
    private var title: LocalizedStringResource {
        switch stage.number {
        case 1: LocalizedStringResource("learn.stage.1", defaultValue: "Stage 1 · Map your loops")
        case 2: LocalizedStringResource("learn.stage.2", defaultValue: "Stage 2 · Update the reward value")
        default: LocalizedStringResource("learn.stage.3", defaultValue: "Stage 3 · Find a bigger, better offer")
        }
    }
}

/// One lesson: its day, ticked once done and ringed when it's next, its title and its reading time.
private struct LessonRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let row: LearnContent.Row
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // At the largest text sizes the title gets its own line under the day and reading time.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        badge
                        Spacer(minLength: 0)
                        minutes
                    }
                    title
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(.rect)
            } else {
                HStack(spacing: 12) {
                    badge
                    title
                    minutes
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 56)
                .contentShape(.rect)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedStringResource(
            "learn.row",
            defaultValue: "Day \(row.lesson.day), \(row.lesson.title)",
        )))
        .accessibilityValue(status)
        .accessibilityAddTraits(.isButton)
    }

    private var title: some View {
        Text(row.lesson.title)
            .font(.theme(row.status == .next ? .headline : .body))
            .foregroundStyle(.theme(.textPrimary))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var minutes: some View {
        Text(LocalizedStringResource("learn.minutes", defaultValue: "\(row.lesson.minutes) min"))
            .font(.theme(.footnote))
            .foregroundStyle(.theme(.textTertiary))
    }

    /// A number inside a fixed circle: capped, as the system caps its own small controls.
    private var badge: some View {
        badgeShape
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    @ViewBuilder private var badgeShape: some View {
        switch row.status {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.theme(.textOnAccent))
                .frame(width: 32, height: 32)
                .background(.theme(.violetStrong), in: .circle)
        case .next:
            Text(row.lesson.day, format: .number)
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.violetOnTint))
                .frame(width: 32, height: 32)
                .background(.theme(.violetTint), in: .circle)
                .overlay { Circle().strokeBorder(.theme(.violetStrong), lineWidth: 2) }
        case .later:
            Text(row.lesson.day, format: .number)
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.textTertiary))
                .frame(width: 32, height: 32)
                .background(.theme(.surfaceSunken), in: .circle)
        }
    }

    private var status: Text {
        switch row.status {
        case .done: Text(LocalizedStringResource("learn.row.done", defaultValue: "Done"))
        case .next: Text(LocalizedStringResource("learn.row.next", defaultValue: "Up next"))
        case .later: Text(verbatim: "")
        }
    }
}

#if DEBUG
    #Preview {
        LearnView { _ in }
            .modelContainer(AppModelContainer.preview)
    }
#endif
