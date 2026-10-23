import Foundation

/// The repository checkout, for tests that check committed files. Simulator tests run on the Mac,
/// so the source tree is readable at the path the test file was compiled from.
enum RepositoryRoot {
    static let url = URL(filePath: #filePath)
        .deletingLastPathComponent() // Support
        .deletingLastPathComponent() // LooseningWorryTests
        .deletingLastPathComponent()
}
