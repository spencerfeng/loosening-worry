import SwiftUI

/// "Get help now": the emergency number, free 24/7 crisis lines for the person's country, and a way to find one
/// anywhere else. All wording is a draft for the psychologist reviewer.
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model = HelpViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringResource("help.title", defaultValue: "Get help now"))
                            .font(.theme(.title))
                            .foregroundStyle(.theme(.textPrimary))
                            .accessibilityAddTraits(.isHeader)
                        Text(intro)
                            .font(.theme(.body))
                            .foregroundStyle(.theme(.textSecondary))
                    }
                    CountryMenu(region: model.region) { model.select($0) }
                    EmergencyCall(contact: model.support.emergency)
                    if !model.support.lines.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(LocalizedStringResource("help.talk", defaultValue: "Talk to someone now"))
                                .font(.theme(.title3))
                                .foregroundStyle(.theme(.textPrimary))
                                .accessibilityAddTraits(.isHeader)
                            ForEach(model.support.lines, id: \.name) { line in
                                CrisisLineCard(line: line)
                            }
                        }
                    }
                    Link(destination: CrisisSupport.findAHelpline) {
                        HStack(spacing: 8) {
                            Text(LocalizedStringResource(
                                "help.elsewhere",
                                defaultValue: "Somewhere else? Find a free helpline in your country",
                            ))
                            .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .accessibilityHidden(true)
                        }
                        .font(.theme(.callout))
                        .foregroundStyle(.theme(.accentText))
                        .padding(14)
                        .frame(minHeight: 52)
                        .helpCard()
                    }
                    Text(LocalizedStringResource(
                        "help.disclaimer",
                        defaultValue: """
                        Loosening Worry is a self-help app. It isn't therapy or medical care, and it can't respond \
                        in an emergency.
                        """,
                    ))
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textTertiary))
                }
                .padding(20)
            }
            .background(.theme(.background))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(LocalizedStringResource("help.done", defaultValue: "Done"))
                    }
                }
            }
        }
    }

    /// The promise about the services is made only where the screen names some.
    private var intro: LocalizedStringResource {
        if model.support.lines.isEmpty {
            LocalizedStringResource(
                "help.intro.noLines",
                defaultValue: "If you're struggling, you don't have to handle it alone.",
            )
        } else {
            LocalizedStringResource(
                "help.intro",
                defaultValue: """
                If you're struggling, you don't have to handle it alone. These services are free and open 24/7.
                """,
            )
        }
    }
}

/// The country Help shows lines for, changeable for this visit. A picker inside the menu ticks the current country.
private struct CountryMenu: View {
    let region: HelpRegion
    let select: (HelpRegion) -> Void

    var body: some View {
        Menu {
            Picker(selection: Binding(get: { region }, set: { select($0) })) {
                ForEach(HelpRegion.all) { region in
                    Text(region.name).tag(region)
                }
            } label: {
                Text(LocalizedStringResource("help.country.picker", defaultValue: "Country"))
            }
        } label: {
            HStack(spacing: 6) {
                Text(LocalizedStringResource("help.country", defaultValue: "Country: \(region.name)"))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .accessibilityHidden(true)
            }
            .font(.theme(.callout))
            .foregroundStyle(.theme(.accentText))
            .frame(minHeight: 44)
        }
        .accessibilityHint(Text(LocalizedStringResource("help.country.hint", defaultValue: "Changes the country")))
    }
}

/// The first thing on the screen: one tap to the emergency number, or where to find it.
private struct EmergencyCall: View {
    let contact: CrisisContact?

    var body: some View {
        if let contact {
            Link(destination: contact.url) {
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .accessibilityHidden(true)
                    Text(LocalizedStringResource(
                        "help.emergency.call",
                        defaultValue: "In danger right now? Call \(contact.display)",
                    ))
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .font(.theme(.headline))
                // The help role is light in dark mode, so the text takes the page's own color to stay readable.
                .foregroundStyle(.theme(.background))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(minHeight: 56)
                .background(.theme(.help), in: .rect(cornerRadius: 18))
            }
        } else {
            Text(LocalizedStringResource(
                "help.emergency.local",
                defaultValue: "In danger right now? Call your local emergency number",
            ))
            .font(.theme(.headline))
            .foregroundStyle(.theme(.help))
            .padding(.vertical, 4)
        }
    }
}

/// One crisis service, with a button for each way to reach it.
private struct CrisisLineCard: View {
    let line: CrisisLine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: line.name)
                    .font(.theme(.headline))
                    .foregroundStyle(.theme(.textPrimary))
                Text(line.detail)
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textTertiary))
            }
            .accessibilityElement(children: .combine)
            // Side by side only when both fit unwrapped; stacked, a button wraps only at the largest text sizes.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { buttons }
                VStack(alignment: .leading, spacing: 8) { buttons }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .helpCard()
    }
}

private extension CrisisLineCard {
    @ViewBuilder var buttons: some View {
        if let call = line.call {
            ContactButton(
                contact: call,
                title: LocalizedStringResource("help.call", defaultValue: "Call \(call.display)"),
                symbol: "phone.fill",
                isFilled: true,
            )
        }
        if let text = line.text {
            ContactButton(
                contact: text,
                title: LocalizedStringResource("help.text", defaultValue: "Text \(text.display)"),
                symbol: "message.fill",
                isFilled: false,
            )
        }
    }
}

/// A capsule that calls or texts: filled for the main way to reach a line, outlined for the other.
private struct ContactButton: View {
    let contact: CrisisContact
    let title: LocalizedStringResource
    let symbol: String
    let isFilled: Bool

    var body: some View {
        Link(destination: contact.url) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: symbol)
            }
            .font(.theme(.callout))
            .foregroundStyle(.theme(isFilled ? .textOnAccent : .accentText))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(.theme(isFilled ? .accent : .surface), in: .capsule)
            .overlay { Capsule().strokeBorder(.theme(.accentOutline), lineWidth: isFilled ? 0 : 1.5) }
        }
    }
}

private extension View {
    /// A rounded surface with a hairline border, for each block on the Help screen.
    func helpCard() -> some View {
        background(.theme(.surface), in: .rect(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.theme(.borderSubtle)) }
    }
}

#Preview {
    HelpView()
}
