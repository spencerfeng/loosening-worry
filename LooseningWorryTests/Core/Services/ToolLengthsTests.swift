import Foundation
@testable import LooseningWorry
import Testing

@MainActor
final class ToolLengthsTests {
    /// Each test gets its own defaults, so nothing leaks between tests or into the app.
    private let suiteName = "ToolLengthsTests.\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test
    func `with nothing chosen, a tool opens at its own length`() {
        #expect(ToolLengths(defaults: defaults).length(for: .breathe) == .seconds(60))
    }

    @Test
    func `a length chosen is the one a tool opens at next time`() {
        ToolLengths(defaults: defaults).remember(.seconds(300), for: .breathe)

        #expect(ToolLengths(defaults: defaults).length(for: .breathe) == .seconds(300))
    }

    /// A length an older version offered, or a mistaken value, falls back rather than running an odd length.
    @Test
    func `a stored length that isn't offered any more is ignored`() {
        ToolLengths(defaults: defaults).remember(.seconds(120), for: .breathe)

        #expect(ToolLengths(defaults: defaults).length(for: .breathe) == .seconds(60))
    }
}
