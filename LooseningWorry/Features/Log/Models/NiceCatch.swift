import Foundation

/// What Nice catch shows once a loop is saved: the loop, what this habit has given the person the last times this
/// trigger set it off, and a tool to try now.
struct NiceCatch {
    /// The loop just saved, which a tool started from here belongs to.
    let loop: Loop
    /// Trigger, behavior and result, as logged.
    let chips: [String]
    /// `nil` until this trigger has led to this habit twice.
    let lastTimes: LastTimes?
    /// The habit just ran and the person may still be stirred up, so it's a tool for right now: Breathe.
    static let suggestion = QuickTool.breathe

    /// - Parameter history: Every loop with this loop's trigger and habit, oldest first, this one included.
    init(loop: Loop, history: [Loop]) {
        self.loop = loop
        chips = [loop.triggerLabel, loop.behaviorLabel, loop.resultLabel]
        lastTimes = LastTimes(loops: history)
    }
}
