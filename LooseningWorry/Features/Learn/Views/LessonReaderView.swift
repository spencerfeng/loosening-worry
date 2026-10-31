import os
import SwiftData
import SwiftUI

/// One lesson, a card at a time: the hook, the ideas, an example, a short exercise and today's task, then a done
/// screen. Closing early leaves the lesson unfinished; today's task button finishes it and goes to the task, and the
/// done screen goes back to Learn.
struct LessonReaderView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reader: LessonReaderViewModel

    /// Closes the reader, with today's task to open next, or `nil` to just close.
    let close: (LessonAction?) -> Void
    let backToLearn: () -> Void

    init(
        lesson: Lesson,
        progress: LessonCompleting,
        close: @escaping (LessonAction?) -> Void,
        backToLearn: @escaping () -> Void,
    ) {
        _reader = State(initialValue: LessonReaderViewModel(lesson: lesson, progress: progress))
        self.close = close
        self.backToLearn = backToLearn
    }

    var body: some View {
        VStack(spacing: 0) {
            ReaderHeader(reader: reader) { close(nil) }
            if reader.isFinished {
                LessonDoneView(reader: reader, backToLearn: backToLearn)
            } else {
                ScrollView {
                    CardView(
                        lesson: reader.lesson,
                        index: reader.index,
                        courseLength: LessonCatalog.bundled.lessons.count,
                    ) {
                        close(reader.startTask(now: .now))
                    }
                    .id(reader.index)
                    .transition(.opacity)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ReaderControls(reader: reader) { change in
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2), change)
                    }
                }
            }
        }
        .background(.theme(.background))
    }
}

/// Close, the lesson's day and length, and a segment per card.
private struct ReaderHeader: View {
    let reader: LessonReaderViewModel
    let close: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button(role: .close, action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.theme(.textPrimary))
                        .frame(width: 44, height: 44)
                        .background(.theme(.surface), in: .circle)
                        .overlay { Circle().strokeBorder(.theme(.border)) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(LocalizedStringResource("lesson.close", defaultValue: "Close")))
                Spacer()
                Text(LocalizedStringResource(
                    "lesson.header",
                    defaultValue: "Day \(reader.lesson.day) · \(reader.lesson.minutes) min",
                ))
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.violetOnTint))
                .lineLimit(1)
                // A label in a pill between two buttons: capped, so it stays on one line.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(.theme(.violetTint), in: .capsule)
                Spacer()
                // Balances Close, so the day stays centered.
                Color.clear.frame(width: 44, height: 44)
            }
            if !reader.isFinished {
                HStack(spacing: 4) {
                    ForEach(reader.lesson.cards.indices, id: \.self) { index in
                        Capsule()
                            .fill(.theme(index <= reader.index ? .violetStrong : .border))
                            .frame(height: 4)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(LocalizedStringResource(
                    "lesson.position",
                    defaultValue: "Card \(reader.index + 1) of \(reader.lesson.cards.count)",
                )))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

/// Back, and Next or, on the last card, Finish lesson.
private struct ReaderControls: View {
    let reader: LessonReaderViewModel
    let animate: (@escaping () -> Void) -> Void

    var body: some View {
        HStack(spacing: 12) {
            if !reader.isFirst {
                Button {
                    animate { reader.back() }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.theme(.textPrimary))
                        .frame(width: 56, height: 56)
                        .background(.theme(.surfaceSunken), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(LocalizedStringResource("lesson.back", defaultValue: "Back")))
            }
            Button {
                animate { reader.next(now: .now) }
            } label: {
                Text(reader.isLast
                    ? LocalizedStringResource("lesson.finish", defaultValue: "Finish lesson")
                    : LocalizedStringResource("lesson.next", defaultValue: "Next"))
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textOnAccent))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(.theme(.accent), in: .capsule)
                    .shadow(color: .theme(.accentShadow).opacity(0.3), radius: 8, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.theme(.background))
    }
}

/// One card: its illustration if it has one, what kind of card it is, its heading and its words.
private struct CardView: View {
    let lesson: Lesson
    let index: Int
    let courseLength: Int
    let startTask: () -> Void

    private var card: LessonCard {
        lesson.cards[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let name = lesson.illustration(at: index), let tint = card.tint {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 342)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(.theme(tint.role), in: .rect(cornerRadius: 24))
                    .accessibilityHidden(true)
            }
            Text(kicker)
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(.violetOnTint))
            if let heading {
                Text(heading)
                    .font(.theme(.title))
                    .foregroundStyle(.theme(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
            }
            Text(LessonText.styled(card.body, style: card.kind == .hook ? .title3 : .body))
                .font(.theme(card.kind == .hook ? .title3 : .body))
                .foregroundStyle(.theme(card.kind == .hook ? .textSecondary : .textPrimary))
                .lineSpacing(5)
            if card.kind == .task, let action = card.action {
                TaskButton(action: action, start: startTask)
                    .padding(.top, 4)
            }
            if let footer = card.footer {
                Text(footer)
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textTertiary))
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The hook is headed by the lesson's title; ideas and today's task by their own.
    private var heading: String? {
        card.kind == .hook ? lesson.title : card.title
    }

    private var kicker: LocalizedStringResource {
        switch card.kind {
        case .hook:
            return LocalizedStringResource(
                "lesson.kicker.hook",
                defaultValue: "Lesson · Day \(lesson.day) of \(courseLength)",
            )
        case .idea:
            let ideas = lesson.cards.count { $0.kind == .idea }
            let number = lesson.cards[...index].count { $0.kind == .idea }
            return LocalizedStringResource("lesson.kicker.idea", defaultValue: "Idea \(number) of \(ideas)")
        case .example:
            return LocalizedStringResource("lesson.kicker.example", defaultValue: "Example")
        case .tryIt:
            let length = Duration.seconds(card.seconds ?? 0).formatted(.units(allowed: [.seconds], width: .abbreviated))
            return LocalizedStringResource("lesson.kicker.try", defaultValue: "Try it now · \(length)")
        case .task:
            return LocalizedStringResource("lesson.kicker.task", defaultValue: "Today's task")
        }
    }
}

/// Today's task button: finishes the lesson and goes to the task.
private struct TaskButton: View {
    let action: LessonAction
    let start: () -> Void

    var body: some View {
        Button(action: start) {
            Label {
                Text(action.label)
            } icon: {
                Image(systemName: action.symbol)
            }
            .font(.theme(.headline))
            .foregroundStyle(.theme(.accentText))
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .background(.theme(.surface), in: .capsule)
            .overlay { Capsule().strokeBorder(.theme(.border)) }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(LocalizedStringResource(
            "lesson.task.hint",
            defaultValue: "Finishes the lesson",
        )))
    }
}

/// After the last card: the lesson is done, today's task, and the next lesson with how far the course has come.
private struct LessonDoneView: View {
    @Query private var progress: [LessonProgress]

    let reader: LessonReaderViewModel
    let backToLearn: () -> Void

    var body: some View {
        let next = HomeContent.nextLesson(progress: progress, catalog: .bundled)
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(.theme(.textOnAccent))
                    .frame(width: 88, height: 88)
                    .background(.theme(.violetStrong), in: .circle)
                    .accessibilityHidden(true)
                Text(LocalizedStringResource("lesson.done.title", defaultValue: "Day \(reader.lesson.day) done"))
                    .font(.theme(.title))
                    .foregroundStyle(.theme(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
                if let task = reader.lesson.cards.last?.title {
                    Text(LocalizedStringResource("lesson.done.task", defaultValue: "Today's task: \(task)"))
                        .font(.theme(.body))
                        .foregroundStyle(.theme(.textSecondary))
                }
                if reader.didFailToSave {
                    Text(LocalizedStringResource(
                        "lesson.done.notSaved",
                        defaultValue: "Couldn't save this lesson as done. It may not show a tick yet.",
                    ))
                    .font(.theme(.footnote))
                    .foregroundStyle(.theme(.textTertiary))
                }
                if let next, next.lesson.day != reader.lesson.day {
                    NextUp(card: next)
                        .padding(.top, 10)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 40)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: backToLearn) {
                Text(LocalizedStringResource("lesson.done.backToLearn", defaultValue: "Back to Learn"))
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textOnAccent))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(.theme(.accent), in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.theme(.background))
        }
    }
}

/// The next lesson and the course's progress, on the done screen; it doesn't open anything.
private struct NextUp: View {
    let card: HomeContent.NextLessonSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringResource("lesson.done.next", defaultValue: "Up next · Day \(card.lesson.day)"))
                    .foregroundStyle(.theme(.violetOnTint))
                Spacer()
                Text(LocalizedStringResource("home.lesson.minutes", defaultValue: "\(card.lesson.minutes) min read"))
                    .foregroundStyle(.theme(.textTertiary))
            }
            .font(.theme(.footnote))
            Text(card.lesson.title)
                .font(.theme(.title3))
                .foregroundStyle(.theme(.textPrimary))
            ProgressView(value: Double(card.daysCompleted), total: Double(max(card.totalDays, 1)))
                .progressViewStyle(CourseProgressStyle())
                .accessibilityHidden(true)
            Text(LocalizedStringResource(
                "home.lesson.progress",
                defaultValue: "\(card.daysCompleted) of \(card.totalDays) lessons done",
            ))
            .font(.theme(.footnote))
            .foregroundStyle(.theme(.textTertiary))
        }
        .multilineTextAlignment(.leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(.theme(.surface), in: .rect(cornerRadius: 22))
        .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(.theme(.borderSubtle)) }
        .accessibilityElement(children: .combine)
    }
}

/// A lesson's words with their `**bold**` and `*italic*` marks applied, in the theme's faces.
enum LessonText {
    static func styled(_ markdown: String, style: Theme.TextStyle) -> AttributedString {
        let text: AttributedString
        do {
            text = try AttributedString(
                markdown: markdown,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace),
            )
        } catch {
            logger.error("Couldn't read a lesson's marks: \(error)")
            return AttributedString(markdown)
        }
        let metrics = style.metrics
        let bold = Font.custom(Theme.FontFace.bold.postScriptName, size: metrics.size, relativeTo: metrics.scalesWith)
        return text.restylingEmphasis(font: bold, color: .theme(.textPrimary))
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LooseningWorry", category: "Lessons")
}

extension LessonCard.Tint {
    var role: Theme.ColorRole {
        switch self {
        case .violet: .violetTint
        case .blue: .accentTint
        case .amber: .amberTint
        case .green: .greenTint
        }
    }
}

extension LessonAction {
    var label: LocalizedStringResource {
        switch self {
        case .logLoop: LocalizedStringResource("lesson.action.log", defaultValue: "Log a loop")
        case .openInsights: LocalizedStringResource("lesson.action.insights", defaultValue: "Open Insights")
        case let .tool(tool): tool.name
        case .openSettings: LocalizedStringResource("lesson.action.settings", defaultValue: "Open Settings")
        }
    }

    var symbol: String {
        switch self {
        case .logLoop: "square.and.pencil"
        case .openInsights: "chart.bar"
        case let .tool(tool): tool.symbol
        case .openSettings: "gearshape"
        }
    }
}

#if DEBUG
    #Preview {
        if let lesson = LessonCatalog.bundled.lesson(day: 2) {
            LessonReaderView(
                lesson: lesson,
                progress: LessonProgressStore(context: AppModelContainer.preview.mainContext),
            ) { _ in } backToLearn: {}
                .modelContainer(AppModelContainer.preview)
        }
    }
#endif
