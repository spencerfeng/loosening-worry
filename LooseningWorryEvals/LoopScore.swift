/// How the README scores a step.
enum LoopScore {
    /// A step left empty, as the cases write it.
    static let none = "none"

    enum Step: Equatable {
        /// One of the answers the case accepts.
        case right
        /// Left empty when an option was expected: a small cost, as the person taps it themselves.
        case notSure
        /// An option the case doesn't accept: the real failure, as the person has to notice and change it.
        case wrong
    }

    static func step(answer: String, expected: [String]) -> Step {
        if expected.contains(answer) {
            .right
        } else if answer == none {
            .notSure
        } else {
            .wrong
        }
    }
}
