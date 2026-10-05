import Foundation

// Routine inspections can't be booked on NSW public holidays (unless the tenant agrees)
protocol NSWPublicHolidays {
    // returns the holiday's name, or nil if it's a normal day
    func holidayName(on date: Date) -> String?
}

// NSW public holidays for 2026 and 2027, copied from the NSW Industrial Relations website.
// Bank Holiday is left out because it only applies to banks.
// TODO: add 2028 before the end of 2027
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
        // turn the date into "yyyy-MM-dd" (in Sydney time) and look it up
        let day = Calendar.sydney.dateComponents([.year, .month, .day], from: date)
        let key = String(format: "%04d-%02d-%02d", day.year!, day.month!, day.day!)
        return GazettedNSWPublicHolidays.holidays[key]
    }
}
