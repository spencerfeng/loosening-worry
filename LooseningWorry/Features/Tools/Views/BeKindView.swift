import SwiftUI

/// Be kind, at the person's own pace: the pages of the self-compassion break, with other wordings to try and phrases
/// to keep, or, for someone with phrases kept, the choice of reading those instead. The heart's glow grows page by
/// page.
struct BeKindView: View {
    @State private var beKind: BeKindViewModel

    init(model: ToolRunViewModel, store: any PhraseKeeping) {
        _beKind = State(initialValue: BeKindViewModel(run: model, store: store))
    }

    var body: some View {
        switch beKind.mode {
        case .choosing: BeKindChoice(beKind: beKind)
        case .steps: BeKindSteps(beKind: beKind)
        case .reading: BeKindReading(beKind: beKind)
        }
    }
}

/// For someone with phrases kept: read them, or go through it again.
private struct BeKindChoice: View {
    let beKind: BeKindViewModel

    var body: some View {
        BeKindPageLayout(glow: 0.6) {
            BeKindWords(
                title: LocalizedStringResource("tool.beKind.choice", defaultValue: "Your kind words are here."),
                guide: LocalizedStringResource(
                    "tool.beKind.choice.guide",
                    defaultValue: "Read the ones you kept, or go through it again.",
                ),
            )
        } controls: {
            VStack(spacing: 6) {
                PrimaryButton(title: LocalizedStringResource("tool.beKind.read", defaultValue: "Read your phrases")) {
                    beKind.readPhrases()
                }
                TextButton(title: LocalizedStringResource("tool.beKind.goThrough", defaultValue: "Go through it")) {
                    withAnimation(.easeOut(duration: 0.35)) { beKind.goThrough() }
                }
            }
        }
    }
}

/// The pages, one at a time, with Back and Next, and Finish on the last.
private struct BeKindSteps: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let beKind: BeKindViewModel

    var body: some View {
        BeKindPageLayout(glow: Double(beKind.pageNumber - 1) / Double(beKind.pageCount - 1)) {
            page
                .id(beKind.page)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 10)))
        } controls: {
            VStack(spacing: 16) {
                PageDots(count: beKind.pageCount, current: beKind.pageNumber - 1)
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeOut(duration: 0.35)) { beKind.back() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.theme(.textPrimary))
                            .frame(width: 56, height: 56)
                            .background(.theme(.surface), in: .circle)
                            .overlay { Circle().strokeBorder(.theme(.border)) }
                            .contentShape(.circle)
                    }
                    .buttonStyle(.plain)
                    // From the first page, Back leads to the choice for someone who came from it.
                    .disabled(backIsOff)
                    .opacity(backIsOff ? 0.4 : 1)
                    .accessibilityLabel(Text(LocalizedStringResource("tool.beKind.back", defaultValue: "Back")))
                    if beKind.isLastPage {
                        PrimaryButton(title: LocalizedStringResource("tool.beKind.finish", defaultValue: "Finish")) {
                            beKind.finish(now: .now)
                        }
                    } else {
                        PrimaryButton(title: LocalizedStringResource("tool.beKind.next", defaultValue: "Next")) {
                            withAnimation(.easeOut(duration: 0.35)) { beKind.next() }
                        }
                    }
                }
            }
        }
    }

    private var backIsOff: Bool {
        beKind.isFirstPage && beKind.keptPhrases.isEmpty
    }

    @ViewBuilder private var page: some View {
        switch beKind.page {
        case .hard, .notAlone, .kindness:
            PhrasePage(beKind: beKind, page: beKind.page)
        case .friend:
            FriendPage(beKind: beKind)
        case .takeAway:
            // The title, the phrase itself, then the line about coming back to it.
            VStack(spacing: 16) {
                Text(KindPage.takeAway.title)
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textSecondary))
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: "\u{201C}\(beKind.shownTakeAway)\u{201D}")
                    .font(.theme(.title))
                    .foregroundStyle(.theme(.redOnTint))
                Text(KindPage.takeAway.guide)
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textSecondary))
                KeepButton(beKind: beKind, text: beKind.shownTakeAway)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 320)
        case .notice, .touch:
            BeKindWords(title: beKind.page.title, guide: beKind.page.guide)
        }
    }
}

/// A phrase, its guiding line, and the ways to make it the person's own: other words, and keeping it.
private struct PhrasePage: View {
    let beKind: BeKindViewModel
    let page: KindPage

    var body: some View {
        let wording = beKind.wording(on: page)
        VStack(spacing: 16) {
            BeKindWords(title: wording?.text ?? page.title, guide: page.guide)
                .id(wording)
                .transition(.opacity)
            HStack(spacing: 8) {
                KeepButton(beKind: beKind, text: beKind.phraseText(on: page) ?? "")
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { beKind.tryOtherWords() }
                } label: {
                    Text(LocalizedStringResource("tool.beKind.otherWords", defaultValue: "Try other words"))
                        .font(.theme(.subheadline))
                        .foregroundStyle(.theme(.accentText))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// What the person would say to a friend, written if they like, and kept if it helps.
private struct FriendPage: View {
    @Bindable var beKind: BeKindViewModel
    @FocusState private var isWriting: Bool

    var body: some View {
        VStack(spacing: 16) {
            BeKindWords(title: KindPage.friend.title, guide: KindPage.friend.guide)
            TextField(
                text: $beKind.ownWords,
                prompt: Text(LocalizedStringResource(
                    "tool.beKind.ownWords.hint",
                    defaultValue: "It's okay to find this hard.",
                )),
                axis: .vertical,
            ) {
                Text(LocalizedStringResource("tool.beKind.ownWords", defaultValue: "Your words"))
            }
            .lineLimit(1 ... 4)
            .font(.theme(.body))
            .foregroundStyle(.theme(.textPrimary))
            .focused($isWriting)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.theme(.surface), in: .rect(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.theme(.border)) }
            .submitLabel(.done)
            // Return closes the keyboard rather than starting a new line.
            .onChange(of: beKind.ownWords) { _, words in
                if words.contains("\n") {
                    beKind.ownWords = words.replacingOccurrences(of: "\n", with: "")
                    isWriting = false
                }
            }
            if beKind.canKeepOwnWords {
                KeepButton(beKind: beKind, text: beKind.ownWords)
            }
        }
    }
}

/// The phrases kept before, each to read and, if it no longer helps, let go of.
private struct BeKindReading: View {
    let beKind: BeKindViewModel

    var body: some View {
        BeKindPageLayout(glow: 1) {
            VStack(spacing: 16) {
                BeKindWords(
                    title: LocalizedStringResource("tool.beKind.yourPhrases", defaultValue: "Your phrases"),
                    guide: LocalizedStringResource(
                        "tool.beKind.yourPhrases.guide",
                        defaultValue: "Words that helped before.",
                    ),
                )
                ForEach(beKind.readingList, id: \.self) { phrase in
                    VStack(spacing: 8) {
                        Text(verbatim: phrase)
                            .font(.theme(.title3))
                            .foregroundStyle(.theme(.textPrimary))
                            .multilineTextAlignment(.center)
                        KeepButton(beKind: beKind, text: phrase)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(.theme(.surface), in: .rect(cornerRadius: 20))
                    .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.theme(.borderSubtle)) }
                }
            }
        } controls: {
            VStack(spacing: 6) {
                PrimaryButton(title: LocalizedStringResource("tool.beKind.finish", defaultValue: "Finish")) {
                    beKind.finish(now: .now)
                }
                TextButton(title: LocalizedStringResource("tool.beKind.goThrough", defaultValue: "Go through it")) {
                    withAnimation(.easeOut(duration: 0.35)) { beKind.goThrough() }
                }
            }
        }
    }
}

/// "Keep this phrase", which turns into "Kept"; tapping again lets it go. Says so if it couldn't be saved.
private struct KeepButton: View {
    let beKind: BeKindViewModel
    let text: String

    var body: some View {
        let isKept = beKind.isKept(text)
        VStack(spacing: 4) {
            Button {
                beKind.toggleKeep(text, now: .now)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isKept ? "heart.fill" : "heart")
                        .accessibilityHidden(true)
                    Text(isKept
                        ? LocalizedStringResource("tool.beKind.kept", defaultValue: "Kept")
                        : LocalizedStringResource("tool.beKind.keep", defaultValue: "Keep this phrase"))
                }
                .font(.theme(.subheadline))
                .foregroundStyle(.theme(isKept ? .redOnTint : .textSecondary))
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(.theme(isKept ? .redTint : .surface), in: .capsule)
                .overlay { Capsule().strokeBorder(.theme(isKept ? .redTint : .border)) }
                .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isKept ? .isSelected : [])
            .accessibilityHint(isKept
                ? Text(LocalizedStringResource("tool.beKind.kept.hint", defaultValue: "Lets it go"))
                : Text(LocalizedStringResource("tool.beKind.keep.hint", defaultValue: "Keeps it to read again")))
            .sensoryFeedback(.selection, trigger: isKept)
            if failed {
                Text(Self.failedText)
                    .font(.theme(.footnote))
                    .foregroundStyle(.theme(.redOnTint))
            }
        }
        .onChange(of: failed) { _, failed in
            if failed {
                AccessibilityNotification.Announcement(String(localized: Self.failedText)).post()
            }
        }
    }

    /// Only beside the words that couldn't be saved.
    private var failed: Bool {
        beKind.failedToKeep == text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let failedText = LocalizedStringResource(
        "tool.beKind.keepFailed",
        defaultValue: "Couldn't save that. Try again.",
    )
}

/// A page's words: its phrase or question, and the quieter line under it.
private struct BeKindWords: View {
    let title: LocalizedStringResource
    let guide: LocalizedStringResource

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.theme(.title))
                .foregroundStyle(.theme(.textPrimary))
                .accessibilityAddTraits(.isHeader)
            Text(guide)
                .font(.theme(.body))
                .foregroundStyle(.theme(.textSecondary))
                .lineSpacing(4)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 320)
    }
}

/// The heart in its glow at the top, the page's words flowing below it, and the page's controls at the bottom. The
/// heart stays put from page to page, however long the words.
private struct BeKindPageLayout<Content: View, Controls: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// How full the glow is, from 0 to 1; it grows as the pages go on.
    let glow: Double
    @ViewBuilder let content: Content
    @ViewBuilder let controls: Controls

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                HeartGlow(glow: glow)
                    .frame(width: dynamicTypeSize.isAccessibilitySize ? 140 : 220)
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            controls
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.theme(.background))
        }
    }
}

/// The design's heart in a warm glow. The glow grows with `glow`, and the heart and its glow breathe slowly, over
/// six seconds, swelling and brightening enough to be seen, inviting a breath or two; under Reduce Motion they hold
/// still. Decoration, so VoiceOver skips it.
private struct HeartGlow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let glow: Double

    var body: some View {
        Group {
            if reduceMotion {
                layers(breath: 0)
            } else {
                // Breathes in and out, three seconds each way, without redrawing every frame.
                PhaseAnimator([0.0, 1.0]) { breath in
                    layers(breath: breath)
                } animation: { _ in
                    .easeInOut(duration: 3)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.6), value: glow)
        .accessibilityHidden(true)
    }

    /// The glow and the heart, `breath` of the way from resting (0) to full (1).
    private func layers(breath: Double) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [.theme(.redTint), .theme(.redTint).opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 120,
                ))
                .opacity((0.35 + 0.65 * glow) * (0.7 + 0.3 * breath))
                .scaleEffect(1 + 0.16 * breath)
            Circle()
                .fill(.theme(.redTint))
                .frame(width: 150, height: 150)
                .scaleEffect((0.85 + 0.3 * glow) * (1 + 0.1 * breath))
            Image(systemName: "heart.fill")
                .font(.system(size: 36))
                .foregroundStyle(.theme(.redStrong))
                .scaleEffect(1 + 0.16 * breath)
                .frame(width: 84, height: 84)
                .background(.theme(.surface), in: .circle)
                .shadow(color: .theme(.redStrong).opacity(0.22), radius: 11, y: 8)
        }
    }
}

/// Where the reader is among the pages.
private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< count, id: \.self) { index in
                Capsule()
                    .fill(.theme(index == current ? .redStrong : (index < current ? .redTint : .border)))
                    .frame(width: index == current ? 22 : 8, height: 8)
            }
        }
        .animation(.easeOut(duration: 0.25), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedStringResource(
            "tool.beKind.pagePosition",
            defaultValue: "Page \(current + 1) of \(count)",
        )))
    }
}

private struct PrimaryButton: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.theme(.headline))
                .foregroundStyle(.theme(.textOnAccent))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(.theme(.accent), in: .capsule)
                .shadow(color: .theme(.accentShadow), radius: 8, y: 6)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

private struct TextButton: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.theme(.callout))
                .foregroundStyle(.theme(.accentText))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
    #Preview {
        BeKindView(model: .preview(.beKind), store: PhraseStore(context: AppModelContainer.preview.mainContext))
    }
#endif
