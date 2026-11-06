import Foundation
import SwiftData

/// Saves the runs of a tool; a run works through this, so tests can stand in a store of their own.
@MainActor
protocol SessionRecording {
    @discardableResult
    func record(_ tool: QuickTool, startedAt: Date, duration: Duration, loop: Loop?) throws -> ToolSession
    func setOutcome(_ outcome: ToolOutcome, on session: ToolSession) throws
    /// The answer to "How do you feel now?" after each run of `tool`; `nil` for a run left unanswered.
    func outcomes(for tool: QuickTool) throws -> [ToolOutcome?]
}

/// Saves each run of a tool once it ends, and the person's answer to "How do you feel now?". Each change is saved
/// straight away.
@MainActor
struct SessionStore: SessionRecording {
    let context: ModelContext

    /// Saves a run of `tool`, belonging to `loop`: the loop just logged, for a tool started from Nice catch, or a new
    /// one
    /// the run brings, for a tool started from the logger's "Nothing yet". If saving fails the session is taken out
    /// again, and so is a new loop, so neither is saved later by mistake.
    @discardableResult
    func record(_ tool: QuickTool, startedAt: Date, duration: Duration, loop: Loop?) throws -> ToolSession {
        let isNewLoop = loop.map { $0.modelContext == nil } ?? false
        let session = ToolSession(tool: tool, startedAt: startedAt, duration: duration, loop: loop)
        context.insert(session)
        do {
            try context.save()
        } catch {
            context.delete(session)
            if isNewLoop, let loop {
                context.delete(loop)
            }
            throw error
        }
        return session
    }

    /// Saves the answer to "How do you feel now?"; answering again replaces it. If saving fails the answer goes back
    /// to what was saved, so it isn't saved later by mistake.
    func setOutcome(_ outcome: ToolOutcome, on session: ToolSession) throws {
        let saved = session.outcome
        session.outcome = outcome
        do {
            try context.save()
        } catch {
            session.outcome = saved
            throw error
        }
    }

    /// Filtered here rather than in a predicate, which can't reliably compare enum properties; a person's runs number
    /// in the hundreds at most.
    func outcomes(for tool: QuickTool) throws -> [ToolOutcome?] {
        try context.fetch(FetchDescriptor<ToolSession>())
            .filter { $0.tool == tool }
            .map(\.outcome)
    }
}
