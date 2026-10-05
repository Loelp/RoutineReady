import Foundation

// What the widget shows. The app saves this to widget-snapshot.json after every change,
// and the widget just reads the file (it never opens Core Data).
nonisolated struct WidgetSnapshot: Codable, Equatable {
    struct UpcomingInspection: Codable, Equatable {
        let scheduledAt: Date
        let address: String
        let suburb: String
    }

    let nextInspection: UpcomingInspection?
    // The rest of today's inspections. Without these the widget would keep showing
    // the 11:15 one after 11:15 until the app was opened again.
    let laterToday: [UpcomingInspection]
    let urgentMaintenanceCount: Int
    let generatedAt: Date

    // the first inspection that hasn't started yet at this time
    func nextInspection(after date: Date) -> UpcomingInspection? {
        var all: [UpcomingInspection] = []
        if let nextInspection = nextInspection {
            all.append(nextInspection)
        }
        all.append(contentsOf: laterToday)

        for inspection in all {
            if inspection.scheduledAt > date {
                return inspection
            }
        }
        return nil
    }
}
