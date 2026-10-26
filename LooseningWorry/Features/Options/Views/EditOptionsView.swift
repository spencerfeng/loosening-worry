import SwiftData
import SwiftUI

/// "Your options": add, remove and restore the person's triggers, behaviors and results. Opened from a logger step,
/// on that step's tab.
struct EditOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var savedOptions: [LoopOption]
    @State private var model: EditOptionsViewModel

    init(kind: OptionKind) {
        _model = State(initialValue: EditOptionsViewModel(kind: kind))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker(selection: kindSelection) {
                    ForEach(OptionKind.allCases, id: \.self) { kind in
                        Text(kind.logCopy.optionsTab).tag(kind)
                    }
                } label: {
                    Text(LocalizedStringResource("edit.tabs", defaultValue: "Option type"))
                }
                .pickerStyle(.segmented)

                if let error = model.editError {
                    Text(error.message)
                        .font(.theme(.subheadline))
                        .foregroundStyle(.theme(.redOnTint))
                }

                if model.isAdding {
                    AddOptionCard(kind: model.kind, draft: $model.draft, error: model.addError, add: add) {
                        withAnimation(animation) { model.cancelAdding() }
                    }
                } else {
                    AddOptionButton(kind: model.kind) {
                        withAnimation(animation) { model.startAdding() }
                    }
                }

                ForEach(model.sections(saved: savedOptions), id: \.kind) { section in
                    OptionSection(section: section, remove: remove, restore: restore)
                }

                Text(model.kind == .result ? Self.resultsFootnote : Self.footnote)
                    .font(.theme(.caption))
                    .foregroundStyle(.theme(.textTertiary))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.theme(.background))
        .onChange(of: model.editError) { _, error in
            if let error {
                AccessibilityNotification.Announcement(String(localized: error.message)).post()
            }
        }
        .navigationTitle(Text(LocalizedStringResource("edit.title", defaultValue: "Your options")))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text(LocalizedStringResource("edit.done", defaultValue: "Done"))
                }
            }
        }
    }

    private var kindSelection: Binding<OptionKind> {
        Binding { model.kind } set: { kind in
            withAnimation(animation) { model.select(kind) }
        }
    }

    private var animation: Animation {
        .easeOut(duration: reduceMotion ? 0.15 : 0.22)
    }

    private func add() {
        withAnimation(animation) {
            model.add(saved: savedOptions) { text in
                _ = try OptionStore(context: modelContext).addOwn(text, kind: model.kind)
            }
        }
    }

    private func remove(_ choice: OptionChoice) {
        withAnimation(animation) {
            model.remove(choice) { try OptionStore(context: modelContext).remove($0) }
        }
    }

    private func restore(_ choice: OptionChoice) {
        let kind = model.kind
        withAnimation(animation) {
            model.restore(choice) { try OptionStore(context: modelContext).restore($0, kind: kind) }
        }
    }

    private static let footnote = LocalizedStringResource(
        "edit.footnote",
        defaultValue: """
        Removed options stop showing in the logger. Past loops keep them, and you can restore them any time. \
        To fix a typo, remove the option and add it again.
        """,
    )

    private static let resultsFootnote = LocalizedStringResource(
        "edit.footnote.results",
        defaultValue: """
        Core results can’t be removed and always stay in the same order, so step 3 never nudges your answer. \
        To fix a typo in your own option, remove it and add it again.
        """,
    )
}

/// Opens the add card: "+ Add a trigger".
private struct AddOptionButton: View {
    let kind: OptionKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .fontWeight(.bold)
                    .accessibilityHidden(true)
                Text(kind.logCopy.addLabel)
            }
            .font(.theme(.callout))
            .foregroundStyle(.theme(.accentText))
            .frame(maxWidth: .infinity, minHeight: 48)
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.theme(.accentOutline), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

/// Where the person types a new option. Return adds it, like the Add button.
private struct AddOptionCard: View {
    let kind: OptionKind
    @Binding var draft: String
    let error: EditOptionsViewModel.AddError?
    let add: () -> Void
    let cancel: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kind.logCopy.addLabel)
                .font(.theme(.footnote))
                .foregroundStyle(.theme(.textTertiary))
                // The field carries the same label.
                .accessibilityHidden(true)
            HStack(spacing: 8) {
                TextField(text: $draft, prompt: Text(kind.logCopy.addPlaceholder)) {
                    Text(kind.logCopy.addLabel)
                }
                .font(.theme(.body))
                .foregroundStyle(.theme(.textPrimary))
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(add)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(.theme(.background), in: .rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.theme(.border)) }

                Button(action: add) {
                    Text(LocalizedStringResource("log.addOwn.add", defaultValue: "Add"))
                        .font(.theme(.callout))
                        .foregroundStyle(.theme(.textOnAccent))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(.theme(.accent), in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
            if let error {
                Text(error.message)
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.redOnTint))
            }
            Button(action: cancel) {
                Text(LocalizedStringResource("edit.add.cancel", defaultValue: "Cancel"))
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.textTertiary))
                    .frame(minHeight: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.theme(.surface), in: .rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.theme(.accent), lineWidth: 2) }
        .onAppear { isFocused = true }
        .onChange(of: error) { _, error in
            if let error {
                // The keyboard stays up so the person can fix the text.
                isFocused = true
                AccessibilityNotification.Announcement(String(localized: error.message)).post()
            }
        }
    }
}

private extension EditOptionsViewModel.AddError {
    var message: LocalizedStringResource {
        switch self {
        case .empty:
            LocalizedStringResource("edit.add.error.empty", defaultValue: "Type a name first.")
        case let .alreadyShowing(text):
            LocalizedStringResource("edit.add.error.showing", defaultValue: "You already have “\(text)”.")
        case let .removed(text):
            LocalizedStringResource(
                "edit.add.error.removed",
                defaultValue: "“\(text)” is in Removed. Restore it instead.",
            )
        case .saveFailed:
            LocalizedStringResource("edit.add.error.saveFailed", defaultValue: "Couldn’t save that. Please try again.")
        }
    }
}

/// One section: a heading, then its options in a card.
private struct OptionSection: View {
    let section: EditSection
    let remove: (OptionChoice) -> Void
    let restore: (OptionChoice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .textCase(.uppercase)
                .font(.theme(.footnote))
                .tracking(0.8)
                .foregroundStyle(.theme(.textTertiary))
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.choice.id) { index, row in
                    if index > 0 {
                        Divider().overlay(.theme(.borderSubtle))
                    }
                    OptionRow(row: row, remove: remove, restore: restore)
                }
            }
            .background(.theme(.surface), in: .rect(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.theme(.borderSubtle)) }
            .clipShape(.rect(cornerRadius: 18))
        }
    }

    private var title: LocalizedStringResource {
        switch section.kind {
        case .yourOwn: LocalizedStringResource("edit.section.yourOwn", defaultValue: "Your own")
        case .starters: LocalizedStringResource("edit.section.starters", defaultValue: "Starters")
        case .coreResults: LocalizedStringResource("edit.section.coreResults", defaultValue: "Core results")
        case let .removed(count): LocalizedStringResource("edit.section.removed", defaultValue: "Removed (\(count))")
        }
    }
}

private struct OptionRow: View {
    let row: EditRow
    let remove: (OptionChoice) -> Void
    let restore: (OptionChoice) -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.label)
                    .font(.theme(.headline))
                    .foregroundStyle(isRemoved ? .theme(.textTertiary) : .theme(.textPrimary))
                if let note = row.note {
                    Text(note.text)
                        .font(.theme(.caption))
                        .foregroundStyle(.theme(.textTertiary))
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            action
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .frame(minHeight: 56)
    }

    private var isRemoved: Bool {
        if case .restore = row.action {
            true
        } else {
            false
        }
    }

    @ViewBuilder private var action: some View {
        switch row.action {
        case .remove:
            Button {
                remove(row.choice)
            } label: {
                Image(systemName: "minus.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(.theme(.redStrong))
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringResource("edit.remove", defaultValue: "Remove \(row.label)")))
        case .locked:
            Image(systemName: "lock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.theme(.textTertiary))
                .frame(width: 44, height: 44)
                .accessibilityLabel(Text(LocalizedStringResource(
                    "edit.locked",
                    defaultValue: "Core result: can’t be removed",
                )))
        case let .restore(isEnabled):
            Button {
                restore(row.choice)
            } label: {
                Text(LocalizedStringResource("edit.restore", defaultValue: "Restore"))
                    .font(.theme(.subheadline))
                    .foregroundStyle(.theme(.accentText))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 40)
                    .background(.theme(.surface), in: .capsule)
                    .overlay { Capsule().strokeBorder(.theme(.border)) }
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.4)
            .accessibilityHint(isEnabled ? Text(verbatim: "") : Text(LocalizedStringResource(
                "edit.restore.blocked",
                defaultValue: "Another option already shows this text.",
            )))
            .accessibilityLabel(Text(LocalizedStringResource(
                "edit.restore.label",
                defaultValue: "Restore \(row.label)",
            )))
        }
    }
}

private extension EditOptionsViewModel.EditError {
    var message: LocalizedStringResource {
        switch self {
        case .removeFailed:
            LocalizedStringResource("edit.error.remove", defaultValue: "Couldn’t remove that. Please try again.")
        case .restoreFailed:
            LocalizedStringResource("edit.error.restore", defaultValue: "Couldn’t restore that. Please try again.")
        }
    }
}

private extension EditRow.Note {
    var text: LocalizedStringResource {
        switch self {
        case .starter: LocalizedStringResource("edit.note.starter", defaultValue: "Starter")
        case .yourOwn: LocalizedStringResource("edit.note.yourOwn", defaultValue: "Your own")
        case .coreResult: LocalizedStringResource("edit.note.coreResult", defaultValue: "Core result")
        }
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            EditOptionsView(kind: .trigger)
        }
        .modelContainer(AppModelContainer.preview)
    }
#endif
