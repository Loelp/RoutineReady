import Foundation
import WidgetKit

struct NextInspectionEntry: TimelineEntry {
    let date: Date
    /// `nil` when there are no more inspections today.
    let inspection: WidgetSnapshot.UpcomingInspection?
    let urgentMaintenanceCount: Int
    /// `false` until the app has written its first snapshot.
    let hasSnapshot: Bool
}

/// Builds the widget timeline from `widget-snapshot.json` in the App Group. It never opens Core Data.
struct NextInspectionProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextInspectionEntry {
        return Self.sampleEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (NextInspectionEntry) -> Void) {
        if context.isPreview {
            completion(Self.sampleEntry)
        } else {
            completion(entry(at: Date(), from: readSnapshot()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextInspectionEntry>) -> Void) {
        let snapshot = readSnapshot()
        let now = Date()
        var entries = [entry(at: now, from: snapshot)]

        // Refresh once the next inspection has started, so the one after it shows up.
        // With nothing left today, refresh at midnight. The app also reloads the widget after every change.
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
        return try? AppGroupJSON.decode(WidgetSnapshot.self, from: data)
    }

    /// Shown in the widget gallery before the user adds the widget.
    static let sampleEntry = NextInspectionEntry(
        date: Date(),
        inspection: WidgetSnapshot.UpcomingInspection(scheduledAt: Date().addingTimeInterval(45 * 60), address: "14 Rose St", suburb: "Yagoona"),
        urgentMaintenanceCount: 2,
        hasSnapshot: true
    )
}
