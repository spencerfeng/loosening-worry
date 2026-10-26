import Foundation

extension Calendar {
    /// When the calendar week holding `date` began, on this calendar's first weekday. Nice catch's count, Home's
    /// summary and Insights all count "this week" from here.
    func startOfWeek(containing date: Date) -> Date? {
        dateInterval(of: .weekOfYear, for: date)?.start
    }
}
