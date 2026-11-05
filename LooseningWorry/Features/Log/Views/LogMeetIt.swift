import SwiftUI

/// Step 2's way to meet the urge while it's happening: "Nothing yet, I'm in it now".
struct LogMeetItCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "scope")
                    .font(.system(size: 18, weight: .bold))
                    // On the strong green, ink is the background, which keeps contrast in dark mode (ADR 0006).
                    .foregroundStyle(.theme(.background))
                    .frame(width: 36, height: 36)
                    .background(.theme(.greenStrong), in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringResource("log.meetIt.title", defaultValue: "Nothing yet, I'm in it now"))
                        .font(.theme(.headline))
                        .foregroundStyle(.theme(.textPrimary))
                    Text(LocalizedStringResource(
                        "log.meetIt.detail",
                        defaultValue: "Meet the urge with a tool instead",
                    ))
                    .font(.theme(.footnote))
                    .foregroundStyle(.theme(.textSecondary))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.theme(.textTertiary))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 60)
            .background(.theme(.greenTint), in: .rect(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.theme(.greenStrong), lineWidth: 1.5) }
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

/// After "Nothing yet": what the person wrote the last time this trigger set them off, then the tools to meet the urge
/// with. Picking one runs it, and its finish saves the loop.
///
/// Like `LogQuestion`, it takes values rather than the view model.
struct LogMeetIt: View {
    /// The last loop with this trigger that has a note, if any.
    let lastNoted: Loop?
    let pick: (QuickTool) -> Void
    /// Back to the habits, keeping the trigger.
    let back: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let lastNoted, let note = lastNoted.note {
                LastTimeCard(note: note, loop: lastNoted)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringResource("log.meetIt.question", defaultValue: "Meet the urge this time"))
                    .font(.theme(.title))
                    .foregroundStyle(.theme(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
                Text(LocalizedStringResource(
                    "log.meetIt.hint",
                    defaultValue: "Turn toward the feeling instead of following it.",
                ))
                .font(.theme(.body))
                .foregroundStyle(.theme(.textSecondary))
            }
            VStack(spacing: 10) {
                ForEach(QuickTool.allCases, id: \.self) { tool in
                    ToolCard(tool: tool, detail: tool.reason) { pick(tool) }
                }
            }
            Button(action: back) {
                Text(LocalizedStringResource("log.meetIt.back", defaultValue: "It already happened"))
                    .font(.theme(.callout))
                    .foregroundStyle(.theme(.accentText))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

/// The person's own words from last time, a reminder of what the habit gave them.
private struct LastTimeCard: View {
    let note: String
    let loop: Loop

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringResource("log.meetIt.lastTime", defaultValue: "Last time"))
                .font(.theme(.callout))
                .foregroundStyle(.theme(.textSecondary))
            Text(verbatim: "\u{201C}\(note)\u{201D}")
                .font(.theme(.title3))
                .foregroundStyle(.theme(.textPrimary))
            Text(verbatim: "\(loop.behaviorLabel) · \(loop.resultLabel)")
                .font(.theme(.footnote))
                .foregroundStyle(.theme(.textTertiary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(cornerRadius: 18)
        .accessibilityElement(children: .combine)
    }
}
