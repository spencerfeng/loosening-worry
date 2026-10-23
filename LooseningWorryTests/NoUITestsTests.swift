import Foundation
import Testing

/// The project has no UI tests and must not gain any (see Agents.md, Testing Requirements).
struct NoUITestsTests {
    private static let repositoryRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    @Test
    func `project spec declares no UI test target`() throws {
        let spec = try String(
            contentsOf: Self.repositoryRoot.appending(path: "project.yml"),
            encoding: .utf8,
        )
        #expect(!spec.contains("bundle.ui-testing"))
    }

    @Test
    func `repository has no UI test sources`() throws {
        let entries = try FileManager.default.contentsOfDirectory(atPath: Self.repositoryRoot.path())
        #expect(!entries.contains { $0.hasSuffix("UITests") })
    }
}
