import Foundation

/// NSW public holidays, on which routine inspections may not be held without the tenant's consent.
protocol NSWPublicHolidays {
    /// The holiday's name if `date` falls on an NSW public holiday (Sydney time), otherwise `nil`.
    func holidayName(on date: Date) -> String?
}

/// NSW public holidays for 2026 and 2027 as published by NSW Industrial Relations
/// (Public Holidays Act 2010). The Bank Holiday is left out: it applies only to banks.
/// Extend this list before 2028.
struct GazettedNSWPublicHolidays: NSWPublicHolidays {
    private static let holidays: [String: String] = [
        "2026-01-01": "New Year's Day",
        "2026-01-26": "Australia Day",
        "2026-04-03": "Good Friday",
        "2026-04-04": "Easter Saturday",
        "2026-04-05": "Easter Sunday",
        "2026-04-06": "Easter Monday",
        "2026-04-25": "Anzac Day",
        "2026-06-08": "King's Birthday",
        "2026-10-05": "Labour Day",
        "2026-12-25": "Christmas Day",
        "2026-12-26": "Boxing Day",
        "2026-12-28": "Boxing Day (additional day)",
        "2027-01-01": "New Year's Day",
        "2027-01-26": "Australia Day",
        "2027-03-26": "Good Friday",
        "2027-03-27": "Easter Saturday",
        "2027-03-28": "Easter Sunday",
        "2027-03-29": "Easter Monday",
        "2027-04-25": "Anzac Day",
        "2027-06-14": "King's Birthday",
        "2027-10-04": "Labour Day",
        "2027-12-25": "Christmas Day",
        "2027-12-26": "Boxing Day",
        "2027-12-27": "Christmas Day (additional day)",
        "2027-12-28": "Boxing Day (additional day)",
    ]

    func holidayName(on date: Date) -> String? {
        let day = Calendar.sydney.dateComponents([.year, .month, .day], from: date)
        let key = String(format: "%04d-%02d-%02d", day.year!, day.month!, day.day!)
        return Self.holidays[key]
    }
}
