@testable import LooseningWorry
import Testing

struct LogStepCopyTests {
    @Test(arguments: OptionKind.allCases)
    func `every step has three different cheers`(step: OptionKind) {
        let keys = step.logCopy.cheers.map(\.key)

        #expect(keys.count == 3)
        #expect(Set(keys).count == keys.count)
    }

    @Test(arguments: [
        (0, "log.behavior.cheer1"),
        (2, "log.behavior.cheer3"),
        (3, "log.behavior.cheer1"),
        (7, "log.behavior.cheer2")
    ])
    func `each new loop gets the next cheer, wrapping after the last`(loopsLogged: Int, key: String) {
        #expect(OptionKind.behavior.logCopy.cheer(afterLoops: loopsLogged).key == key)
    }
}
