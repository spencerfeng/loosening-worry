/// What an interpreter read from a sentence describing a loop.
struct LoopReading: Equatable {
    /// The option picked for each step the sentence tells, by id. A step it doesn't tell is left out.
    var picks: [OptionKind: String] = [:]
    /// A new option in the person's own words, for each step the sentence tells that none of their options fits. A step
    /// can have both, when the interpreter gets it wrong; the logger then offers only the pick.
    var newOptions: [OptionKind: String] = [:]
}
