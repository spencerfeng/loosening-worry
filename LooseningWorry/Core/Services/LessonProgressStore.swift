import Foundation
import SwiftData

/// Saves which lessons of the course are done.
struct LessonProgressStore {
    let context: ModelContext

    /// Marks `day` done at `date`. A lesson already done keeps its first date, and synced devices that each saved a row
    /// for the day all count as one. If saving fails the change is undone, so it isn't saved later by mistake.
    func complete(day: Int, at date: Date) throws {
        let rows = try context.fetch(FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.day == day }))
        guard !rows.contains(where: { $0.completedAt != nil }) else { return }
        if let row = rows.first {
            row.completedAt = date
            do {
                try context.save()
            } catch {
                row.completedAt = nil
                throw error
            }
        } else {
            let row = LessonProgress(day: day)
            row.completedAt = date
            context.insert(row)
            do {
                try context.save()
            } catch {
                context.delete(row)
                throw error
            }
        }
    }

    /// The first lesson not yet done, or `nil` once all are.
    func nextLesson(in catalog: LessonCatalog) throws -> Lesson? {
        let progress = try context.fetch(FetchDescriptor<LessonProgress>())
        return HomeContent.nextLesson(progress: progress, catalog: catalog)?.lesson
    }
}
