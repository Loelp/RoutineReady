import Foundation

// The NSW limits on routine inspections.
// Source: Residential Tenancies Act 2010 (NSW) s 55 and NSW Fair Trading.
enum RoutineInspectionRules {
    static let minimumNoticeDays = 7
    static let annualLimit = 4                 // max inspections in any 12 months
    static let permittedStartHours = 8..<20    // 8:00 am up to 7:59 pm

    // the date 12 months before the given date (start of the rolling window)
    static func annualWindowStart(endingAt date: Date, calendar: Calendar = .sydney) -> Date {
        return calendar.date(byAdding: .year, value: -1, to: date)!
    }
}
