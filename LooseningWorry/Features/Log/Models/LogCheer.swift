/// Encouragement shown after a step is answered.
struct LogCheer: Equatable {
    let step: OptionKind
    /// How many loops the person logged before this one; picks which of the step's cheers to show.
    let loopsLogged: Int
}
