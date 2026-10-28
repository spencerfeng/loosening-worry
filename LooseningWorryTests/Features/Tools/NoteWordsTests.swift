@testable import LooseningWorry
import Testing

struct NoteWordsTests {
    /// Noting's three places attention goes: thoughts, the body and the senses.
    @Test
    func `the words come in three groups: thinking, body and senses`() {
        let groups = NoteWords.groups

        #expect(groups.map(\.id) == ["thinking", "body", "senses"])
        #expect(groups[0].words.map(\.id) == [.worrying, .planning, .judging, .remembering])
        #expect(groups[1].words.map(\.id) == [.tight, .restless, .heavy, .calm])
        #expect(groups[2].words.map(\.id) == [.hearing, .seeing, .touching])
    }

    /// "Something" fits any group, so nobody freezes looking for the right word.
    @Test
    func `something stands on its own, after the groups`() {
        #expect(NoteWords.catchAll.id == .something)
        #expect(!NoteWords.groups.flatMap(\.words).contains(NoteWords.catchAll))
    }

    @Test
    func `every word is different`() {
        let ids = NoteWords.all.map(\.id)

        #expect(Set(ids).count == ids.count)
        #expect(Set(ids) == Set(NoteWordID.allCases))
    }
}
