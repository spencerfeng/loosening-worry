import Foundation
@testable import LooseningWorry
import Testing

/// Saving each run as a session, with the feeling answered on the finish screen.
extension ToolRunViewModelTests {
    @Test
    func `a started run is saved as it ends, with its tool, start and length`() throws {
        let model = model(.curious)
        model.play(now: start.addingTimeInterval(5))

        model.end(now: start.addingTimeInterval(65))

        let session = try #require(sessions.sessions.only)
        #expect(session.tool == .curious)
        #expect(session.startedAt == start.addingTimeInterval(5))
        #expect(session.durationSeconds == 60)
    }

    @Test
    func `a run that ends on time is saved too`() {
        let model = model(.breathe)
        model.play(now: start)

        model.tick(now: start.addingTimeInterval(61))

        #expect(sessions.sessions.map(\.durationSeconds) == [60])
    }

    /// Ending before starting isn't a session; nor is closing, which never reaches the finish screen.
    @Test
    func `a run ended before it started saves nothing`() {
        let model = model(.curious)

        model.end(now: start.addingTimeInterval(10))

        #expect(sessions.sessions.isEmpty)
    }

    /// Be kind's time runs from when it opens, but it's a session only once the person goes past the first page.
    @Test
    func `a Be kind run is saved once the person has engaged, timed from when it opened`() {
        let opened = model(.beKind)
        opened.end(now: start.addingTimeInterval(5))
        #expect(sessions.sessions.isEmpty)

        let model = model(.beKind)
        model.markEngaged()
        model.end(now: start.addingTimeInterval(80))

        #expect(sessions.sessions.map(\.startedAt) == [start])
        #expect(sessions.sessions.map(\.durationSeconds) == [80])
    }

    @Test
    func `the feeling answered is saved with the session, and changing it updates it`() {
        let model = model(.curious)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        model.choose(.lighter)
        model.choose(.same)

        #expect(sessions.sessions.map(\.feeling) == [.same])
    }

    @Test
    func `another tool from the finish screen is saved as its own session`() {
        let model = model(.curious)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))
        model.choose(.heavier)

        model.start(.breathe, now: start.addingTimeInterval(40))
        model.play(now: start.addingTimeInterval(40))
        model.end(now: start.addingTimeInterval(70))
        model.choose(.lighter)

        #expect(sessions.sessions.map(\.tool) == [.curious, .breathe])
        #expect(sessions.sessions.map(\.feeling) == [.heavier, .lighter])
    }

    @Test
    func `a tool started from Nice catch belongs to its loop`() throws {
        let loop = Loop(
            trigger: OptionChoice(.work, label: "Work"),
            behavior: OptionChoice(.overthought, label: "Overthought it"),
            result: OptionChoice(.moreWorry, label: "More worry"),
        )
        let model = model(.curious, loop: loop)
        model.play(now: start)

        model.end(now: start.addingTimeInterval(30))

        #expect(try #require(sessions.sessions.only).loop === loop)
    }

    /// Saving can fail; the finish screen still works, and says the session wasn't saved.
    @Test
    func `a session that couldn't be saved is marked, and the finish screen still works`() {
        sessions.failing = true
        let model = model(.curious)
        model.play(now: start)

        model.end(now: start.addingTimeInterval(30))
        model.choose(.lighter)

        #expect(model.stage == .finished)
        #expect(model.feeling == .lighter)
        #expect(model.saveFailure == .session)
    }

    /// The session saved; only the answer didn't, so the screen says that, not that the session failed.
    @Test
    func `an answer that couldn't be saved is told apart from the session`() {
        sessions.failingFeeling = true
        let model = model(.curious)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        model.choose(.lighter)

        #expect(sessions.sessions.count == 1)
        #expect(model.saveFailure == .feeling)
    }

    /// The time actually spent, which Back 15 doesn't take away from.
    @Test
    func `a session lasts the time spent running, whatever Back 15 did`() {
        let model = model(.curious)
        model.play(now: start)
        model.goBack(now: start.addingTimeInterval(40))

        model.end(now: start.addingTimeInterval(50))

        #expect(sessions.sessions.map(\.durationSeconds) == [50])
    }

    @Test
    func `another tool starts with no failure shown`() {
        sessions.failing = true
        let model = model(.curious)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        model.start(.breathe, now: start.addingTimeInterval(40))

        #expect(model.saveFailure == nil)
    }

    @Test
    func `an answer with no session saved is kept on screen only`() {
        let model = model(.curious)
        model.end(now: start.addingTimeInterval(10))

        model.choose(.same)

        #expect(model.feeling == .same)
        #expect(sessions.sessions.isEmpty)
        #expect(model.saveFailure == nil)
    }

    /// The whole sitting started from Nice catch is the person's response to that loop.
    @Test
    func `another tool after one from Nice catch belongs to the same loop`() {
        let loop = Loop(
            trigger: OptionChoice(.work, label: "Work"),
            behavior: OptionChoice(.overthought, label: "Overthought it"),
            result: OptionChoice(.moreWorry, label: "More worry"),
        )
        let model = model(.curious, loop: loop)
        model.play(now: start)
        model.end(now: start.addingTimeInterval(30))

        model.start(.breathe, now: start.addingTimeInterval(40))
        model.play(now: start.addingTimeInterval(40))
        model.end(now: start.addingTimeInterval(70))

        #expect(sessions.sessions.allSatisfy { $0.loop === loop })
        #expect(sessions.sessions.count == 2)
    }
}
