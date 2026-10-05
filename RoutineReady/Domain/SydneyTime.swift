import Foundation

extension Calendar {
    // The rules are always checked in Sydney time, even if the phone is set to another time zone.
    static let sydney: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        calendar.locale = Locale(identifier: "en_AU")
        return calendar
    }()
}

extension Date {
    // e.g. "Tue 14 Oct"
    var inspectionDayText: String {
        return Date.dayFormatter.string(from: self)
    }

    // e.g. "11:15 am"
    var inspectionTimeText: String {
        return Date.timeFormatter.string(from: self)
    }

    private static let dayFormatter = makeSydneyFormatter("EEE d MMM")
    private static let timeFormatter = makeSydneyFormatter("h:mm a")

    private static func makeSydneyFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.timeZone = Calendar.sydney.timeZone
        formatter.dateFormat = format
        return formatter
    }
}
