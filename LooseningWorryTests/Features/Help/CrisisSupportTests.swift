import Foundation
@testable import LooseningWorry
import Testing

/// Help is the crisis path, so every number is pinned, as each service publishes it.
struct CrisisSupportTests {
    @Test(arguments: [
        ("AU", HelpRegion.australia), ("US", .unitedStates), ("GB", .unitedKingdom),
        ("NZ", .other), ("CA", .other),
    ])
    func `the device's region picks the country`(code: String, region: HelpRegion) {
        #expect(HelpRegion(regionCode: code) == region)
    }

    /// Territories whose people dial the same emergency number and reach the same lines. Not the Crown Dependencies:
    /// Samaritans answers there, but Shout's short code isn't confirmed on their networks.
    @Test(arguments: [("PR", HelpRegion.unitedStates), ("VI", .unitedStates), ("JE", .other), ("IM", .other)])
    func `a territory that shares a country's lines gets that country`(code: String, region: HelpRegion) {
        #expect(HelpRegion(regionCode: code) == region)
    }

    @Test
    func `no region at all gets the help for anywhere else`() {
        #expect(HelpRegion(regionCode: nil) == .other)
    }

    @Test
    func `in Australia: Triple Zero, and Lifeline by call or text`() throws {
        let support = HelpRegion.australia.support

        #expect(support.emergency?.display == "000")
        #expect(support.emergency?.url.absoluteString == "tel:000")
        let lifeline = try #require(support.lines.only)
        #expect(lifeline.name == "Lifeline")
        #expect(lifeline.call?.display == "13 11 14")
        #expect(lifeline.call?.url.absoluteString == "tel:131114")
        #expect(lifeline.text?.display == "0477 13 11 14")
        #expect(lifeline.text?.url.absoluteString == "sms:0477131114")
    }

    @Test
    func `the US: 911, and 988 by call or text`() throws {
        let support = HelpRegion.unitedStates.support

        #expect(support.emergency?.url.absoluteString == "tel:911")
        let lifeline = try #require(support.lines.only)
        #expect(lifeline.name == "988 Suicide & Crisis Lifeline")
        #expect(lifeline.call?.url.absoluteString == "tel:988")
        #expect(lifeline.text?.url.absoluteString == "sms:988")
    }

    /// Samaritans takes calls only; Shout is the UK's crisis text line, reached by texting SHOUT.
    @Test
    func `the UK: 999, Samaritans by call and Shout by text`() {
        let support = HelpRegion.unitedKingdom.support

        #expect(support.emergency?.url.absoluteString == "tel:999")
        #expect(support.lines.map(\.name) == ["Samaritans", "Shout"])
        #expect(support.lines[0].call?.url.absoluteString == "tel:116123")
        #expect(support.lines[0].text == nil)
        #expect(support.lines[1].call == nil)
        #expect(support.lines[1].text?.display == "85258")
        #expect(support.lines[1].text?.url.absoluteString == "sms:85258?body=SHOUT")
    }

    /// Without a country there's no one number to call, so Help points to a directory of free helplines.
    @Test
    func `anywhere else: no emergency number, and a directory of helplines`() {
        let support = HelpRegion.other.support

        #expect(support.emergency == nil)
        #expect(support.lines.isEmpty)
        #expect(CrisisSupport.findAHelpline.absoluteString == "https://findahelpline.com")
    }
}
