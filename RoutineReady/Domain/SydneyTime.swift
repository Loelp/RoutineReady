import Foundation

extension Calendar {
    /// All rules are judged in Sydney local time, whatever time zone the device is set to.
    static let sydney: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        calendar.locale = Locale(identifier: "en_AU")
        return calendar
    }()
}

extension Date {
    /// "Tue 14 Oct", as written on a notice of entry.
    var inspectionDayText: String { Self.dayFormatter.string(from: self) }

    /// "11:15 am"
    var inspectionTimeText: String { Self.timeFormatter.string(from: self) }

    private static let dayFormatter = sydneyFormatter("EEE d MMM")
    private static let timeFormatter = sydneyFormatter("h:mm a")

    private static func sydneyFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.timeZone = Calendar.sydney.timeZone
        formatter.dateFormat = format
        return formatter
    }
}
