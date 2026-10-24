import Foundation
import SwiftData

/// Completion of one lesson in the 30-day course.
@Model
final class LessonProgress {
    /// 1–30.
    var day: Int = 1
    var completedAt: Date?
    /// When "For you today" last suggested revisiting this lesson after the course, so it isn't repeated daily.
    var lastRevisitedAt: Date?

    init(day: Int) {
        self.day = day
    }
}
