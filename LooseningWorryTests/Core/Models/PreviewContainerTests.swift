import Foundation
@testable import LooseningWorry
import SwiftData
import Testing

@MainActor
struct PreviewContainerTests {
    @Test
    func `the preview store never syncs`() {
        let configurations = AppModelContainer.preview.configurations

        #expect(!configurations.isEmpty)
        #expect(configurations.allSatisfy { $0.isStoredInMemoryOnly && $0.cloudKitContainerIdentifier == nil })
    }

    @Test
    func `the preview has at least ten complete loops`() throws {
        let loops = try AppModelContainer.preview.mainContext.fetch(FetchDescriptor<Loop>())

        #expect(loops.count >= 10)
        #expect(loops.allSatisfy { !$0.triggerLabel.isEmpty && !$0.behaviorLabel.isEmpty && !$0.resultLabel.isEmpty })
        #expect(loops.allSatisfy { !$0.triggerID.isEmpty && !$0.behaviorID.isEmpty && !$0.resultID.isEmpty })
    }

    /// Weekly counts and charts need loops on several days of the past week, none in the future.
    @Test
    func `the preview's loops are spread over the past week`() throws {
        let loops = try AppModelContainer.preview.mainContext.fetch(FetchDescriptor<Loop>())
        let weekAgo = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)

        #expect(loops.allSatisfy { $0.createdAt > weekAgo && $0.createdAt <= .now })
        let days = Set(loops.map { Calendar.current.startOfDay(for: $0.createdAt) })
        #expect(days.count >= 5)
    }

    // The logger previews every way the person can shape their options.

    @Test
    func `the preview has a custom option`() throws {
        let saved = try savedOptions()

        #expect(choices(from: saved).contains { $0.starterID == nil })
    }

    @Test
    func `the preview hides a starter, keeping its full label`() throws {
        let saved = try savedOptions()
        let hidden = saved.filter { $0.starterID != nil && $0.isHidden }
        try #require(!hidden.isEmpty)

        let choices = choices(from: saved)
        for option in hidden {
            #expect(!choices.contains { $0.starterID == option.starter })
            #expect(!option.label.isEmpty)
        }
    }

    private func savedOptions() throws -> [LoopOption] {
        try AppModelContainer.preview.mainContext.fetch(FetchDescriptor<LoopOption>())
    }

    private func choices(from saved: [LoopOption]) -> [OptionChoice] {
        [OptionKind.trigger, .behavior, .result].flatMap { OptionList.choices(for: $0, saved: saved) }
    }

    @Test
    func `the preview has a tool session started from a loop and lessons completed from day one`() throws {
        let context = AppModelContainer.preview.mainContext
        let sessions = try context.fetch(FetchDescriptor<ToolSession>())
        let completedDays = try context.fetch(FetchDescriptor<LessonProgress>())
            .filter { $0.completedAt != nil }
            .map(\.day)
            .sorted()

        #expect(sessions.contains { $0.loop != nil && $0.feeling != nil })
        try #require(completedDays.count >= 3)
        #expect(completedDays == Array(1 ... completedDays.count))
    }
}
