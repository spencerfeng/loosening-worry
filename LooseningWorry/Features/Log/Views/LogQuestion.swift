import SwiftUI

/// The current step's question and its options; tapping one answers the step.
///
/// It takes values, not the view model, so a question that is leaving shows what it last showed. If it watched the
/// model, the answer just picked would animate in the leaving question, and SwiftUI keeps a leaving view on screen
/// until its animations finish, so its options would sit over the next question's.
struct LogQuestion: View {
    /// Scroll target for the add-your-own field, so the logger can keep it above the keyboard.
    static let addOwnFieldID = "LogQuestion.addOwnField"

    let step: OptionKind
    /// The choices to show now; with `hasMore`, the first few of them.
    let choices: [OptionChoice]
    let hasMore: Bool
    /// The id of the step's answer, if it has one.
    let selectedID: String?
    let isAddingOwn: Bool
    @Binding var draft: String
    let canAddOwn: Bool
    /// Offers "Nothing yet, I'm in it now" above the choices; step 2 only.
    let meetIt: (() -> Void)?
    let pick: (OptionChoice) -> Void
    let showMore: () -> Void
    /// Opens Edit options on this step's tab.
    let edit: () -> Void
    let toggleAddOwn: () -> Void
    let addOwn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(step.copy.question)
                        .font(.theme(.title))
                        .foregroundStyle(.theme(.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                    EditLink(label: step.copy.editLabel, action: edit)
                }
                Text(step.copy.hint)
                    .font(.theme(.body))
                    .foregroundStyle(.theme(.textSecondary))
            }
            if let meetIt {
                LogMeetItCard(action: meetIt)
            }
            FlowLayout(spacing: 8) {
                ForEach(choices, id: \.label) { choice in
                    SelectableChip(verbatim: choice.label, isSelected: choice.id == selectedID) {
                        pick(choice)
                    }
                }
                if hasMore {
                    MoreChip(action: showMore)
                }
                AddOwnChip(isOpen: isAddingOwn, action: toggleAddOwn)
            }
            if isAddingOwn {
                AddOwnField(step: step, draft: $draft, canAdd: canAddOwn, add: addOwn)
                    .id(Self.addOwnFieldID)
            }
        }
    }
}
