import SwiftUI

/// The next lesson, and how far through the course the person is; opens the lesson. On Home, headed "Lesson", and
/// atop Learn, headed "Up next", where it sits above the whole list.
struct NextLessonCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let card: HomeContent.NextLessonSummary
    var heading = Heading.lesson
    let action: () -> Void

    enum Heading {
        case lesson, upNext
    }

    var body: some View {
        // The day and the reading time stack at the largest text sizes rather than crowd one line.
        let topRow = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout())
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                topRow {
                    Text(dayLine)
                        .foregroundStyle(.theme(.violetOnTint))
                    if !dynamicTypeSize.isAccessibilitySize {
                        Spacer()
                    }
                    Text(LocalizedStringResource(
                        "home.lesson.minutes",
                        defaultValue: "\(card.lesson.minutes) min read",
                    ))
                    .foregroundStyle(.theme(.textTertiary))
                }
                .font(.theme(.footnote))
                HStack(spacing: 12) {
                    Text(card.lesson.title)
                        .font(.theme(.title3))
                        .foregroundStyle(.theme(.textPrimary))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.theme(.textOnAccent))
                        .frame(width: 40, height: 40)
                        .background(.theme(.violetStrong), in: .circle)
                        .accessibilityHidden(true)
                }
                ProgressView(value: Double(card.daysCompleted), total: Double(max(card.totalDays, 1)))
                    .progressViewStyle(CourseProgressStyle())
                    .accessibilityLabel(Text(LocalizedStringResource(
                        "home.lesson.progress",
                        defaultValue: "\(card.daysCompleted) of \(card.totalDays) lessons done",
                    )))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(.theme(.surface), in: .rect(cornerRadius: 22))
            .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(.theme(.borderSubtle)) }
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(LocalizedStringResource("home.lesson.hint", defaultValue: "Opens the lesson")))
    }

    private var dayLine: LocalizedStringResource {
        switch heading {
        case .lesson:
            LocalizedStringResource(
                "home.lesson.day",
                defaultValue: "Lesson · Day \(card.lesson.day) of \(card.totalDays)",
            )
        case .upNext:
            LocalizedStringResource(
                "learn.upNext",
                defaultValue: "Up next · Day \(card.lesson.day) of \(card.totalDays)",
            )
        }
    }
}

/// The course's progress as a thin violet bar.
struct CourseProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(.theme(.violetTint))
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.theme(.violetStrong))
                        .frame(width: proxy.size.width * (configuration.fractionCompleted ?? 0))
                }
            }
    }
}
