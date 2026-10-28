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
        #expect(session.feeling == nil)
        #expect(session.loop == nil)
    }

    @Test
    func `the feeling answered is saved with the session, and a changed answer replaces it`() throws {
        let session = try store.record(.curious, startedAt: start, duration: .seconds(90), loop: nil)

        try store.setFeeling(.lighter, on: session)
        try store.setFeeling(.same, on: session)

        let saved = try #require(try container.mainContext.fetch(FetchDescriptor<ToolSession>()).first)
        #expect(saved.feeling == .same)
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
