import Foundation
import WidgetKit

struct NextInspectionEntry: TimelineEntry {
    let date: Date
    // nil when there's nothing left today
    let inspection: WidgetSnapshot.UpcomingInspection?
    let urgentMaintenanceCount: Int
    // false if the app hasn't saved a snapshot yet
    let hasSnapshot: Bool
}

// Reads widget-snapshot.json from the App Group and makes the timeline. Doesn't touch Core Data.
struct NextInspectionProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextInspectionEntry {
        return NextInspectionProvider.sampleEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (NextInspectionEntry) -> Void) {
        if context.isPreview {
            completion(NextInspectionProvider.sampleEntry)
        } else {
            completion(entry(at: Date(), from: readSnapshot()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextInspectionEntry>) -> Void) {
        let snapshot = readSnapshot()
        let now = Date()
        var entries = [entry(at: now, from: snapshot)]

        // Ask for a new timeline once the next inspection starts so the one after it shows.
        // If there's nothing left, wait until midnight. (The app also reloads the widget whenever something changes.)
        var refreshDate = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        if let next = snapshot?.nextInspection(after: now) {
            entries.append(entry(at: next.scheduledAt, from: snapshot))
            refreshDate = next.scheduledAt
        }
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    private func entry(at date: Date, from snapshot: WidgetSnapshot?) -> NextInspectionEntry {
        return NextInspectionEntry(
            date: date,
            inspection: snapshot?.nextInspection(after: date),
            urgentMaintenanceCount: snapshot?.urgentMaintenanceCount ?? 0,
            hasSnapshot: snapshot != nil
        )
    }

    private func readSnapshot() -> WidgetSnapshot? {
        guard let data = try? Data(contentsOf: AppGroup.widgetSnapshotURL) else {
            return nil
        }
        return try? AppGroupJSON.makeDecoder().decode(WidgetSnapshot.self, from: data)
    }

    // fake data for the widget gallery
    static let sampleEntry = NextInspectionEntry(
        date: Date(),
        inspection: WidgetSnapshot.UpcomingInspection(scheduledAt: Date().addingTimeInterval(45 * 60), address: "14 Rose St", suburb: "Yagoona"),
        urgentMaintenanceCount: 2,
        hasSnapshot: true
    )
}
