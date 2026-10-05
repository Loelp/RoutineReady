import Foundation

/// The NSW limits on routine inspections (Residential Tenancies Act 2010 s 55; NSW Fair Trading).
enum RoutineInspectionRules {
    /// Calendar days of written notice the tenant must receive.
    static let minimumNoticeDays = 7
    /// Non-cancelled routine inspections allowed in any rolling 12 months.
    static let annualLimit = 4
    /// An inspection may start from 08:00 up to 19:59.
    static let permittedStartHours = 8..<20

    /// Start of the rolling 12-month window that ends at `date` (inclusive at both ends).
    static func annualWindowStart(endingAt date: Date, calendar: Calendar = .sydney) -> Date {
        calendar.date(byAdding: .year, value: -1, to: date)!
    }
}
