@testable import LooseningWorry
import Testing

struct CrisisWordingTests {
    @Test(arguments: [
        "I can't go on like this, everything at work is falling apart.",
        "Some days I think everyone would be better off without me.",
        "I've been thinking about hurting myself when the worry gets bad.",
        "i just want to die",
        "I DONT WANT TO BE HERE ANYMORE",
        "thinking of ending my life",
        "Cant go on",
    ])
    func `crisis wording is spotted`(sentence: String) {
        #expect(CrisisWording.appears(in: sentence))
    }

    @Test(arguments: [
        "Big deadline tomorrow, I overthought it all night and felt worse.",
        "This commute is killing me, kept checking the train times.",
        "My manager sent a vague email so I kept refreshing my inbox.",
        "",
    ])
    func `everyday worry isn't`(sentence: String) {
        #expect(!CrisisWording.appears(in: sentence))
    }

    /// Typed apostrophes are often curly.
    @Test
    func `curly apostrophes count`() {
        #expect(CrisisWording.appears(in: "I can\u{2019}t go on"))
    }
}
