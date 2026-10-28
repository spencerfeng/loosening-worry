import Foundation

/// A word to note something with, by its stable id; only these exist. Its label is translated.
enum NoteWordID: String, CaseIterable {
    case worrying, planning, judging, remembering
    case tight, restless, heavy, calm
    case hearing, seeing, touching
    case something

    var label: LocalizedStringResource {
        switch self {
        case .worrying: LocalizedStringResource("tool.noteIt.worrying", defaultValue: "worrying")
        case .planning: LocalizedStringResource("tool.noteIt.planning", defaultValue: "planning")
        case .judging: LocalizedStringResource("tool.noteIt.judging", defaultValue: "judging")
        case .remembering: LocalizedStringResource("tool.noteIt.remembering", defaultValue: "remembering")
        case .tight: LocalizedStringResource("tool.noteIt.tight", defaultValue: "tight")
        case .restless: LocalizedStringResource("tool.noteIt.restless", defaultValue: "restless")
        case .heavy: LocalizedStringResource("tool.noteIt.heavy", defaultValue: "heavy")
        case .calm: LocalizedStringResource("tool.noteIt.calm", defaultValue: "calm")
        case .hearing: LocalizedStringResource("tool.noteIt.hearing", defaultValue: "hearing")
        case .seeing: LocalizedStringResource("tool.noteIt.seeing", defaultValue: "seeing")
        case .touching: LocalizedStringResource("tool.noteIt.touching", defaultValue: "touching")
        case .something: LocalizedStringResource("tool.noteIt.something", defaultValue: "something")
        }
    }
}

/// One word to note something with.
struct NoteWord: Identifiable, Hashable {
    let id: NoteWordID

    var label: LocalizedStringResource {
        id.label
    }
}

/// A group of words for one place attention goes. Its name is for VoiceOver; on screen each group is a row.
struct NoteGroup: Identifiable {
    let id: String
    let name: LocalizedStringResource
    let words: [NoteWord]
}

/// Note it's words, from mental noting: one plain, neutral label for what's here, so the person steps back from the
/// story. Thoughts, the body (sensations rather than emotions, which pull back into the story) and the senses, with
/// "calm" so a settled moment can be noted too, and "something" for anything else. They stay the same every session,
/// so they're found by memory. Drafts for the psychologist reviewer.
enum NoteWords {
    static let groups = [
        NoteGroup(
            id: "thinking",
            name: LocalizedStringResource("tool.noteIt.group.thinking", defaultValue: "Thinking"),
            words: [.worrying, .planning, .judging, .remembering].map(NoteWord.init),
        ),
        NoteGroup(
            id: "body",
            name: LocalizedStringResource("tool.noteIt.group.body", defaultValue: "Body"),
            words: [.tight, .restless, .heavy, .calm].map(NoteWord.init),
        ),
        NoteGroup(
            id: "senses",
            name: LocalizedStringResource("tool.noteIt.group.senses", defaultValue: "Senses"),
            words: [.hearing, .seeing, .touching].map(NoteWord.init),
        ),
    ]

    /// For anything the groups don't name, so there's never a wrong label.
    static let catchAll = NoteWord(id: .something)

    static var all: [NoteWord] {
        groups.flatMap(\.words) + [catchAll]
    }
}
