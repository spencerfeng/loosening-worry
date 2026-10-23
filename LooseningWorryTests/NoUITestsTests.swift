import Foundation
import Testing

/// The project has no UI tests and must not gain any (see Agents.md, Testing Requirements).
struct NoUITestsTests {
    @Test
    func `project spec declares no UI test target`() throws {
        let spec = try String(
            contentsOf: RepositoryRoot.url.appending(path: "project.yml"),
            encoding: .utf8,
        )
        #expect(!spec.contains("bundle.ui-testing"))
    }

    @Test
    func `repository has no UI test sources`() throws {
        let entries = try FileManager.default.contentsOfDirectory(atPath: RepositoryRoot.url.path())
        #expect(!entries.contains { $0.hasSuffix("UITests") })
    }
}
