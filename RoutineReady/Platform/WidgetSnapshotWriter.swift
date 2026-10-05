import Foundation
import WidgetKit

/// After every change, rewrites the two small files the extensions read from the App Group, then reloads the widget:
/// - `widget-snapshot.json`: the next inspection today and the urgent maintenance count, for the widget;
/// - `share-inspections.json`: today's scheduled inspections, offered by the share extension's picker.
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
            // The booking itself succeeded; a stale widget is not worth failing it for.
            print("Could not refresh the widget snapshot: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func writeWidgetSnapshot(stops: [RunSheetStop]) throws {
        var upcoming: [WidgetSnapshot.UpcomingInspection] = []
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
        try AppGroupJSON.encode(snapshot).write(to: AppGroup.widgetSnapshotURL, options: .atomic)
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
        try AppGroupJSON.encode(shareable).write(to: AppGroup.shareInspectionsURL, options: .atomic)
    }
}
