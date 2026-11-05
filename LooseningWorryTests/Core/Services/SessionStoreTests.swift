import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
struct SessionStoreTests {
    private let container: ModelContainer
    private let start = Date(timeIntervalSince1970: 1_793_000_000)

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
    }

    private var store: SessionStore {
        SessionStore(context: container.mainContext)
    }

    @Test
    func `a session is saved with its tool, when it started and how long it ran`() throws {
        try store.record(.breathe, startedAt: start, duration: .seconds(61.6), loop: nil)

        let session = try #require(try container.mainContext.fetch(FetchDescriptor<ToolSession>()).first)
        #expect(session.tool == .breathe)
        #expect(session.startedAt == start)
        #expect(session.durationSeconds == 62)
        #expect(session.outcome == nil)
        #expect(session.loop == nil)
    }

    /// A run from the logger's "Nothing yet" brings a loop that isn't stored yet; saving the run stores it too, with
    /// the result the finish screen gives it.
    @Test
    func `a new loop belonging to a session is saved with it, and so is its result`() throws {
        let loop = Loop.sample(trigger: OptionChoice(.work, label: "Work"))
        let session = try store.record(.curious, startedAt: start, duration: .seconds(90), loop: loop)
        loop.setResult(ToolOutcome.lighter.asResult)
        try store.setOutcome(.lighter, on: session)

        let saved = try ModelContext(container).fetch(FetchDescriptor<Loop>())
        #expect(saved.map(\.resultID) == ["outcome.lighter"])
        #expect(saved.first?.toolSessions?.count == 1)
    }

    @Test
    func `the feeling answered is saved with the session, and a changed answer replaces it`() throws {
        let session = try store.record(.curious, startedAt: start, duration: .seconds(90), loop: nil)

        try store.setOutcome(.lighter, on: session)
        try store.setOutcome(.same, on: session)

        let saved = try #require(try container.mainContext.fetch(FetchDescriptor<ToolSession>()).first)
        #expect(saved.outcome == .same)
    }

    @Test
    func `a tool's feelings leave out other tools and runs left unanswered`() throws {
        let first = try store.record(.curious, startedAt: start, duration: .seconds(90), loop: nil)
        try store.setOutcome(.lighter, on: first)
        try store.record(.curious, startedAt: start, duration: .seconds(90), loop: nil)
        let breathe = try store.record(.breathe, startedAt: start, duration: .seconds(60), loop: nil)
        try store.setOutcome(.heavier, on: breathe)
        let last = try store.record(.curious, startedAt: start, duration: .seconds(90), loop: nil)
        try store.setOutcome(.same, on: last)

        #expect(try store.outcomes(for: .curious).sorted { $0.rawValue < $1.rawValue } == [.lighter, .same])
    }

    /// A tool started from Nice catch belongs to the loop just logged.
    @Test
    func `a session can belong to a loop`() throws {
        let loop = Loop(
            trigger: OptionChoice(.work, label: "Work"),
            behavior: OptionChoice(.overthought, label: "Overthought it"),
            result: OptionChoice(.moreWorry, label: "More worry"),
        )
        container.mainContext.insert(loop)

        try store.record(.curious, startedAt: start, duration: .seconds(90), loop: loop)

        #expect(loop.toolSessions?.count == 1)
    }
}
