import Foundation
@testable import LooseningWorry

/// Stands in for the session store: keeps what was recorded, and fails when told to.
@MainActor
final class FakeSessionRecorder: SessionRecording {
    private(set) var sessions: [ToolSession] = []
    /// Fails to save sessions.
    var failing = false
    /// Saves sessions, but fails to save the feeling.
    var failingOutcome = false
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

    func setOutcome(_ outcome: ToolOutcome, on session: ToolSession) throws {
        if failing || failingOutcome {
            throw Failed()
        }
        session.outcome = outcome
    }

    func outcomes(for tool: QuickTool) throws -> [ToolOutcome?] {
        if failingReads {
            throw Failed()
        }
        return sessions.filter { $0.tool == tool }.map(\.outcome)
    }

    /// Runs of `tool` from before, one per outcome; `nil` is a run left unanswered.
    func saveEarlier(_ tool: QuickTool, outcomes: [ToolOutcome?]) {
        for outcome in outcomes {
            let session = ToolSession(tool: tool)
            session.outcome = outcome
            sessions.append(session)
        }
    }
}
