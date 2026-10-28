import SwiftUI

/// Note it: tap one plain word each time something shows up. Each word floats up from the "What's here?" circle as a
/// bubble, its chip counts it, and the tally keeps the three noted most. The first word starts the time, which runs
/// on past its target until End; a quiet line says when the target's reached. Only the footer reads the clock, so
/// the words aren't redrawn as it ticks.
struct NoteItView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: ToolRunViewModel
    @State private var noteIt: NoteItViewModel
    @State private var bubbles: [Bubble] = []

    init(model: ToolRunViewModel) {
        self.model = model
        _noteIt = State(initialValue: NoteItViewModel(run: model, now: .now))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottom) {
                    ForEach(bubbles) { bubble in
                        BubbleView(bubble: bubble) {
                            bubbles.removeAll { $0.id == bubble.id }
                        }
                    }
                    AskCircle(noteIt: noteIt)
                }
                .frame(maxWidth: .infinity)
                .frame(height: reduceMotion ? 150 : 270, alignment: .bottom)
                Text(LocalizedStringResource(
                    "tool.noteIt.instruction",
                    defaultValue: "Tap one word each time you notice something.",
                ))
                .font(.theme(.callout))
                .foregroundStyle(.theme(.textSecondary))
                .multilineTextAlignment(.center)
                // Words close together, groups further apart, so each row of a group reads as one.
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(NoteWords.groups) { group in
                        FlowLayout(spacing: 8) {
                            ForEach(group.words) { word in
                                chip(word)
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(Text(group.name))
                    }
                    chip(NoteWords.catchAll)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if footerScrolls {
                    NoteItFooter(run: model, tally: noteIt.tally)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !footerScrolls {
                NoteItFooter(run: model, tally: noteIt.tally)
            }
        }
        .sensoryFeedback(.selection, trigger: noteIt.notesSoFar)
    }

    /// At accessibility sizes the footer would cover the words, so it scrolls with them instead of staying put.
    private var footerScrolls: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private func chip(_ word: NoteWord) -> some View {
        NoteChip(word: word, timesNoted: noteIt.count(of: word)) {
            let before = noteIt.notesSoFar
            noteIt.note(word, now: .now)
            // Only a word actually noted floats up.
            if noteIt.notesSoFar > before, !reduceMotion {
                bubbles.append(Bubble(id: noteIt.notesSoFar, label: word.label))
            }
        }
    }
}

/// One word on its way up: where it rises from, varied so bubbles don't stack.
private struct Bubble: Identifiable {
    let id: Int
    let label: LocalizedStringResource

    /// Across the circle and either side of it, stepping through the width so each bubble lands somewhere new.
    var x: CGFloat {
        CGFloat((id * 67) % 230) - 115
    }
}

/// As the design has it: pops up from the circle, rises 210 points over 4.5 seconds, staying clear until most of the
/// way, then fades and takes itself away. Decoration, so VoiceOver skips it.
private struct BubbleView: View {
    let bubble: Bubble
    let finished: () -> Void
    @State private var shown = false
    @State private var risen = false
    @State private var faded = false

    var body: some View {
        Text(bubble.label)
            .font(.theme(.callout))
            .foregroundStyle(.theme(.amberOnTint))
            .lineLimit(1)
            // A label in a small bubble: capped, so it isn't cut off at the screen's edges.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(.theme(.amberTint), in: .capsule)
            .shadow(color: .theme(.amberStrong).opacity(0.18), radius: 6, y: 4)
            .scaleEffect(shown ? (risen ? 0.92 : 1) : 0.6)
            .offset(x: bubble.x, y: risen ? -210 : (shown ? -60 : -40))
            .opacity(shown && !faded ? 1 : 0)
            .accessibilityHidden(true)
            .task {
                withAnimation(.easeOut(duration: 0.5)) { shown = true }
                withAnimation(.easeOut(duration: 4.5)) { risen = true }
                do {
                    try await Task.sleep(for: .seconds(3.2))
                    withAnimation(.easeIn(duration: 1.3)) { faded = true }
                    try await Task.sleep(for: .seconds(1.4))
                } catch {
                    return
                }
                finished()
            }
    }
}

/// The design's "What's here? · one word" circle. It stays still while the person is noting, and swells once after
/// each quiet spell, asking again; a word noted mid-swell lets it ease back. Still under Reduce Motion.
private struct AskCircle: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let noteIt: NoteItViewModel
    @State private var isSwelling = false

    var body: some View {
        VStack(spacing: 2) {
            Text(LocalizedStringResource("tool.noteIt.ask", defaultValue: "What's here?"))
                .font(.theme(.title3))
                .foregroundStyle(.theme(.textPrimary))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(LocalizedStringResource("tool.noteIt.oneWord", defaultValue: "one word"))
                .font(.theme(.caption))
                .foregroundStyle(.theme(.textTertiary))
        }
        .multilineTextAlignment(.center)
        // Words inside a fixed circle: capped, as the system caps its own small controls.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(6)
        .frame(width: 132, height: 132)
        .background(.theme(.surface), in: .circle)
        .overlay { Circle().strokeBorder(.theme(.amberTint), lineWidth: 2) }
        .background {
            Circle().fill(.theme(.amberStrong).opacity(isSwelling ? 0.14 : 0))
                .padding(isSwelling ? -14 : 0)
        }
        .scaleEffect(isSwelling ? 1.06 : 1)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        // Sleeps until the next quiet spell ends rather than redrawing all the time; each word noted starts it again.
        .task(id: noteIt.notesSoFar) {
            withAnimation(.easeOut(duration: 0.3)) { isSwelling = false }
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(noteIt.nextNudge(after: .now).timeIntervalSinceNow))
                    withAnimation(.easeInOut(duration: 0.6)) { isSwelling = true }
                    try await Task.sleep(for: .seconds(0.6))
                    withAnimation(.easeInOut(duration: 0.6)) { isSwelling = false }
                    try await Task.sleep(for: .seconds(0.6))
                } catch {
                    return
                }
            }
        }
    }
}

/// A word to tap, with how many times it's been noted.
private struct NoteChip: View {
    let word: NoteWord
    let timesNoted: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(word.label)
                    .font(.theme(.callout))
                    .foregroundStyle(.theme(.textPrimary))
                if timesNoted > 0 {
                    Text(timesNoted, format: .number)
                        .font(.theme(.caption2))
                        .foregroundStyle(.theme(.amberOnTint))
                        .padding(.horizontal, 6)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(.theme(.amberTint), in: .capsule)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(.theme(.surface), in: .capsule)
            .overlay { Capsule().strokeBorder(.theme(.borderSubtle)) }
            .shadow(color: .black.opacity(0.06), radius: 1.5, y: 1)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityValue(timesNoted > 0 ? Text(Self.noted(timesNoted)) : Text(verbatim: ""))
    }

    /// "noted 2 times", a plural in the catalog.
    private static func noted(_ count: Int) -> String {
        String(localized: LocalizedStringResource("tool.noteIt.noted", defaultValue: "noted \(count) times"))
    }
}

/// The tally, the line once the target's passed, and the reminder that any label will do. The one part of the screen
/// that reads the clock.
private struct NoteItFooter: View {
    let run: ToolRunViewModel
    let tally: [NoteItViewModel.Tally]

    var body: some View {
        VStack(spacing: 10) {
            if !tally.isEmpty {
                Text(tallyText)
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.textSecondary))
            }
            if run.isPastLength {
                Text(pastTargetText)
                    .font(.theme(.footnote))
                    .foregroundStyle(.theme(.amberOnTint))
                    .transition(.opacity)
            }
            Text(LocalizedStringResource(
                "tool.noteIt.anyLabel",
                defaultValue: "No wrong labels. \u{201C}Something\u{201D} counts too.",
            ))
            .font(.theme(.caption))
            .foregroundStyle(.theme(.textTertiary))
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.theme(.background))
        .animation(.easeInOut(duration: 0.3), value: run.isPastLength)
        // A soft nudge as the target passes; the line above says the rest.
        .sensoryFeedback(.impact(flexibility: .soft), trigger: run.isPastLength) { _, isPast in isPast }
    }

    /// "So far: worrying ×2 · tight ×1"
    private var tallyText: String {
        let items = tally.map { item in
            let word = String(localized: item.word.label)
            return String(localized: LocalizedStringResource(
                "tool.noteIt.tallyItem",
                defaultValue: "\(word) ×\(item.count)",
            ))
        }
        let joined = items.joined(separator: " · ")
        return String(localized: LocalizedStringResource("tool.noteIt.tally", defaultValue: "So far: \(joined)"))
    }

    /// "That's 90 seconds. …", from the tool's own target.
    private var pastTargetText: LocalizedStringResource {
        let target = (run.length ?? .zero).formatted(.units(allowed: [.seconds], width: .wide))
        return LocalizedStringResource(
            "tool.noteIt.pastTarget",
            defaultValue: "That's \(target). Keep noting, or tap End when you're ready.",
        )
    }
}

#if DEBUG
    #Preview {
        NoteItView(model: .preview(.noteIt))
    }
#endif
