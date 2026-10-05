import Foundation

/// Everything the "Next inspection" widget shows, written by the app to `widget-snapshot.json`.
/// The widget never opens Core Data; it only decodes this file.
nonisolated struct WidgetSnapshot: Codable, Equatable {
    struct UpcomingInspection: Codable, Equatable {
        let scheduledAt: Date
        let address: String
        let suburb: String
    }

    /// The next routine inspection still to start today, if any.
    let nextInspection: UpcomingInspection?
    /// Today's inspections after `nextInspection`, so the timeline can move on without the app running.
    let laterToday: [UpcomingInspection]
    /// Urgent maintenance items not yet resolved, across the whole portfolio.
    let urgentMaintenanceCount: Int
    let generatedAt: Date

    /// The first inspection that has not started by `date`.
    func nextInspection(after date: Date) -> UpcomingInspection? {
        ([nextInspection].compactMap { $0 } + laterToday).first { $0.scheduledAt > date }
    }
}
