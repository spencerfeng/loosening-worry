import Foundation
@testable import LooseningWorry
import Testing

struct ReminderTimeTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney") ?? .gmt
        return calendar
    }()

    private let day = Date(timeIntervalSince1970: 1_793_000_000)

    @Test
    func `a reminder time shows in the picker as that time on the given day`() {
        let date = ReminderTime(hour: 7, minute: 30).date(on: day, calendar: calendar)

        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let today = calendar.dateComponents([.year, .month, .day], from: day)
        #expect(parts.hour == 7)
        #expect(parts.minute == 30)
        #expect(parts.second == 0)
        #expect([parts.year, parts.month, parts.day] == [today.year, today.month, today.day])
    }

    @Test
    func `a time picked in the picker keeps only its hour and minute`() {
        let picked = calendar.date(from: DateComponents(
            year: 2026,
            month: 11,
            day: 3,
            hour: 21,
            minute: 45,
            second: 12,
        ))

        let time = picked.map { ReminderTime(date: $0, calendar: calendar) }

        #expect(time == ReminderTime(hour: 21, minute: 45))
    }
}
