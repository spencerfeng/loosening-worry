@testable import LooseningWorry
import Testing
import UIKit

struct ThemeFontTests {
    @Test(arguments: Theme.FontFace.allCases)
    func `face is bundled and registered`(face: Theme.FontFace) {
        #expect(UIFont(name: face.postScriptName, size: 17) != nil)
    }
}
