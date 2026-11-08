/// Which way a step-by-step flow last moved, so the step it shows can come in from the side it lies on: a later step
/// from the trailing edge, an earlier one from the leading edge.
enum StepDirection: Equatable {
    case forward, back
}
