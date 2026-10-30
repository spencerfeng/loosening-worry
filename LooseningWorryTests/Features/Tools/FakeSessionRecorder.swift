import Foundation
@testable import LooseningWorry

/// Stands in for the session store: keeps what was recorded, and fails when told to.
@MainActor
final class FakeSessionRecorder: SessionRecording {
    private(set) var sessions: [ToolSession] = []
    /// Fails to save sessions.
    var failing = false
    /// Saves sessions, but fails to save the feeling.
    var failingFeeling = false
    /// Fails to read earlier feelings.
    var failingReads = false

    struct Failed: Error {}

    func record(_ tool: QuickTool, startedAt: Date, duration: Duration, loop: Loop?) throws -> ToolSession {
        if failing {
            throw Failed()
        }
        let session = ToolSession(tool: tool, startedAt: startedAt, duration: duration, loop: loop)
        sessions.append(session)
        return session
    }

    func setFeeling(_ feeling: Feeling, on session: ToolSession) throws {
        if failing || failingFeeling {
            throw Failed()
        }
        session.feeling = feeling
    }

    func feelings(for tool: QuickTool) throws -> [Feeling] {
        if failingReads {
            throw Failed()
        }
        return sessions.filter { $0.tool == tool }.compactMap(\.feeling)
    }

    /// Runs of `tool` from before, one per feeling; `nil` is a run left unanswered.
    func saveEarlier(_ tool: QuickTool, feelings: [Feeling?]) {
        for feeling in feelings {
            let session = ToolSession(tool: tool)
            session.feeling = feeling
            sessions.append(session)
        }
    }
}
