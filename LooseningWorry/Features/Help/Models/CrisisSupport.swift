import Foundation

/// A country Help knows crisis lines for, or everywhere else. Each country is one entry below: the device regions it
/// covers, its name and its help.
struct HelpRegion: Hashable, Identifiable {
    /// The country's own region code, or "other".
    let id: String
    /// Device regions that dial the same emergency number and reach the same lines.
    let regionCodes: Set<String>
    let name: LocalizedStringResource
    let support: CrisisSupport

    static let all: [HelpRegion] = [australia, unitedStates, unitedKingdom, other]

    /// The country for a device region code, such as `Locale.current.region?.identifier`.
    init(regionCode: String?) {
        self = Self.all.first { region in regionCode.map(region.regionCodes.contains) ?? false } ?? .other
    }

    private init(id: String, regionCodes: Set<String>, name: LocalizedStringResource, support: CrisisSupport) {
        self.id = id
        self.regionCodes = regionCodes
        self.name = name
        self.support = support
    }

    static func == (lhs: HelpRegion, rhs: HelpRegion) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Every number is as the service publishes it (checked October 2026); the wording is a draft for the psychologist
/// reviewer.
extension HelpRegion {
    static let australia = HelpRegion(
        id: "AU",
        regionCodes: ["AU"],
        name: LocalizedStringResource("help.region.australia", defaultValue: "Australia"),
        support: CrisisSupport(emergency: .call("000"), lines: [
            CrisisLine(name: "Lifeline", detail: talkDetail, call: .call("13 11 14"), text: .text("0477 13 11 14"))
        ]),
    )

    /// 988 and 911 also serve Puerto Rico and the US Virgin Islands.
    static let unitedStates = HelpRegion(
        id: "US",
        regionCodes: ["US", "PR", "VI"],
        name: LocalizedStringResource("help.region.unitedStates", defaultValue: "United States"),
        support: CrisisSupport(emergency: .call("911"), lines: [
            CrisisLine(
                name: "988 Suicide & Crisis Lifeline",
                detail: talkDetail,
                call: .call("988"),
                text: .text("988"),
            )
        ]),
    )

    /// Samaritans takes calls only; Shout is the UK's crisis text line, reached by texting SHOUT.
    static let unitedKingdom = HelpRegion(
        id: "GB",
        regionCodes: ["GB"],
        name: LocalizedStringResource("help.region.unitedKingdom", defaultValue: "United Kingdom"),
        support: CrisisSupport(emergency: .call("999"), lines: [
            CrisisLine(name: "Samaritans", detail: talkDetail, call: .call("116 123"), text: nil),
            CrisisLine(
                name: "Shout",
                detail: LocalizedStringResource(
                    "help.line.shout",
                    defaultValue: "Text SHOUT to talk by message with a trained volunteer",
                ),
                call: nil,
                text: .text("85258", keyword: "SHOUT"),
            ),
        ]),
    )

    /// Help can't know the local number here, so it points to Find A Helpline instead.
    static let other = HelpRegion(
        id: "other",
        regionCodes: [],
        name: LocalizedStringResource("help.region.other", defaultValue: "Somewhere else"),
        support: CrisisSupport(emergency: nil, lines: []),
    )

    private static let talkDetail = LocalizedStringResource(
        "help.line.talk",
        defaultValue: "Talk to a trained crisis supporter",
    )
}

/// The help for one country: its emergency number and its free 24/7 crisis lines.
struct CrisisSupport: Equatable {
    /// `nil` where Help can't know the local number.
    let emergency: CrisisContact?
    let lines: [CrisisLine]

    /// Find A Helpline, by ThroughLine: free helplines in 175+ countries, for anywhere Help has no lines of its own.
    static let findAHelpline = crisisLink("https://findahelpline.com")
}

/// One crisis service: its name, what it offers, and how to reach it.
struct CrisisLine: Equatable {
    /// The service's own name, which isn't translated.
    let name: String
    let detail: LocalizedStringResource
    let call: CrisisContact?
    let text: CrisisContact?
}

/// A number to call or text, as people write it and as a link that opens the Phone or Messages app.
struct CrisisContact: Equatable {
    /// The number as the service writes it, such as "13 11 14".
    let display: String
    let url: URL

    static func call(_ display: String) -> CrisisContact {
        CrisisContact(display: display, url: crisisLink("tel:\(digits(display))"))
    }

    /// A text to `display`, starting the message with `keyword` when the service asks for one.
    static func text(_ display: String, keyword: String? = nil) -> CrisisContact {
        let body = keyword.map { "?body=\($0)" } ?? ""
        return CrisisContact(display: display, url: crisisLink("sms:\(digits(display))\(body)"))
    }

    private static func digits(_ display: String) -> String {
        display.filter(\.isNumber)
    }
}

/// Every link on the crisis path is written here by hand, so one that doesn't parse is a bug to catch in testing,
/// never a dead button to ship.
private func crisisLink(_ string: String) -> URL {
    guard let url = URL(string: string) else { preconditionFailure("Not a link: \(string)") }
    return url
}
