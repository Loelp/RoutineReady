import Foundation
import WidgetKit

// Runs after every change. Rewrites the two JSON files in the App Group and then reloads the widget:
//  - widget-snapshot.json: next inspection today + urgent item count (for the widget)
//  - share-inspections.json: today's inspections (for the picker in the share extension)
class WidgetSnapshotWriter: WidgetSnapshotWriting {
    private let loadTodaysRunSheet: LoadTodaysRunSheet
    private let inspections: InspectionRepository
    private let clock: DateProviding

    init(loadTodaysRunSheet: LoadTodaysRunSheet, inspections: InspectionRepository, clock: DateProviding) {
        self.loadTodaysRunSheet = loadTodaysRunSheet
        self.inspections = inspections
        self.clock = clock
    }

    func refreshWidgetSnapshot() {
        do {
            let stops = try loadTodaysRunSheet.execute()
            try writeWidgetSnapshot(stops: stops)
            try writeShareInspections(stops: stops)
        } catch {
            // the booking etc. already saved fine, so just log this rather than showing an error
            print("Could not refresh the widget snapshot: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func writeWidgetSnapshot(stops: [RunSheetStop]) throws {
        var upcoming: [WidgetSnapshot.UpcomingInspection] = []
        // only inspections that haven't started yet
        for stop in stops where stop.inspection.scheduledAt > clock.now {
            upcoming.append(WidgetSnapshot.UpcomingInspection(
                scheduledAt: stop.inspection.scheduledAt,
                address: stop.property.address,
                suburb: stop.property.suburb
            ))
        }
        let snapshot = WidgetSnapshot(
            nextInspection: upcoming.first,
            laterToday: Array(upcoming.dropFirst()),
            urgentMaintenanceCount: try inspections.urgentUnresolvedMaintenanceItems().count,
            generatedAt: clock.now
        )
        try AppGroupJSON.makeEncoder().encode(snapshot).write(to: AppGroup.widgetSnapshotURL, options: .atomic)
    }

    private func writeShareInspections(stops: [RunSheetStop]) throws {
        var shareable: [ShareableInspection] = []
        for stop in stops {
            shareable.append(ShareableInspection(
                id: stop.inspection.id,
                address: "\(stop.property.address), \(stop.property.suburb)",
                scheduledAt: stop.inspection.scheduledAt
            ))
        }
        try AppGroupJSON.makeEncoder().encode(shareable).write(to: AppGroup.shareInspectionsURL, options: .atomic)
    }
}
