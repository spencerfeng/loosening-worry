/// Where one of a loop's steps stands in the logger.
enum StepProgress: Equatable {
    /// Answered, and not being asked.
    case answered
    /// Being asked for the first time.
    case current
    /// Answered, and opened again from the summary card to change the answer.
    case reopened
    /// Not reached yet.
    case upcoming

    /// Whether this is the step being asked now.
    var isCurrent: Bool {
        self == .current || self == .reopened
    }
}
