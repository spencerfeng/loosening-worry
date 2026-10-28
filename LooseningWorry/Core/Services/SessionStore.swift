import Foundation
import SwiftData

/// Saves the runs of a tool; a run works through this, so tests can stand in a store of their own.
@MainActor
protocol SessionRecording {
    @discardableResult
    func record(_ tool: QuickTool, startedAt: Date, duration: Duration, loop: Loop?) throws -> ToolSession
    func setFeeling(_ feeling: Feeling, on session: ToolSession) throws
}

/// Saves each run of a tool once it ends, and the person's answer to "How do you feel now?". Each change is saved
/// straight away.
@MainActor
struct SessionStore: SessionRecording {
    let context: ModelContext

    /// Saves a run of `tool`, belonging to `loop` when it was started from Nice catch. If saving fails the session is
    /// taken out again, so it isn't saved later by mistake.
    @discardableResult
    func record(_ tool: QuickTool, startedAt: Date, duration: Duration, loop: Loop?) throws -> ToolSession {
        let session = ToolSession(tool: tool, startedAt: startedAt, duration: duration, loop: loop)
        context.insert(session)
        do {
            try context.save()
        } catch {
            context.delete(session)
            throw error
        }
        return session
    }

    /// Saves the answer to "How do you feel now?"; answering again replaces it. If saving fails the answer goes back
    /// to what was saved, so it isn't saved later by mistake.
    func setFeeling(_ feeling: Feeling, on session: ToolSession) throws {
        let saved = session.feeling
        session.feeling = feeling
        do {
            try context.save()
        } catch {
            session.feeling = saved
            throw error
        }
    }
}
