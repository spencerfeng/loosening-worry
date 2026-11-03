/// Where one step of a flow stands: the logger's three, the check-in's two.
enum StepProgress: Equatable {
    /// Answered, and not being asked.
    case answered
    /// Being asked for the first time.
    case current
    /// Answered, and opened again to change the answer, as from the logger's summary card.
    case reopened
    /// Not reached yet.
    case upcoming

    /// Whether this is the step being asked now.
    var isCurrent: Bool {
        self == .current || self == .reopened
    }
}
