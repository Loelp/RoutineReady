import SwiftUI
import WidgetKit

/// "Next inspection": where the property manager needs to be next, glanceable between stops.
struct RoutineReadyWidget: Widget {
    let kind = "RoutineReadyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextInspectionProvider()) { entry in
            NextInspectionWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next inspection")
        .description("Your next routine inspection today and the urgent maintenance backlog.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct NextInspectionWidgetView: View {
    let entry: NextInspectionEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            lockScreenView
        case .systemMedium:
            HStack(alignment: .top) {
                nextInspectionView
                Spacer()
                urgentItemsView
                    .frame(maxWidth: 130, alignment: .leading)
            }
        default:
            nextInspectionView
        }
    }

    private var nextInspectionView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT INSPECTION")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            if let inspection = entry.inspection {
                Text(timeText(inspection.scheduledAt, withAmPm: true))
                    .font(.title2.bold())
                Text(inspection.address)
                    .font(.headline)
                    .lineLimit(2)
                Text(inspection.suburb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(emptyText)
                    .font(.headline)
            }
            Spacer(minLength: 0)
        }
    }

    private var urgentItemsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(entry.urgentMaintenanceCount > 0 ? .red : .secondary)
            Text(urgentText)
                .font(.subheadline)
        }
    }

    /// e.g. "11:15 · 14 Rose St, Yagoona"
    private var lockScreenView: some View {
        VStack(alignment: .leading) {
            Text("Next inspection")
                .font(.caption.bold())
            if let inspection = entry.inspection {
                Text("\(timeText(inspection.scheduledAt, withAmPm: false)) · \(inspection.address), \(inspection.suburb)")
                    .lineLimit(2)
            } else {
                Text(emptyText)
            }
        }
    }

    private var emptyText: String {
        return entry.hasSnapshot ? "No more inspections today" : "Open RoutineReady to load today's run sheet"
    }

    private var urgentText: String {
        switch entry.urgentMaintenanceCount {
        case 0: return "No urgent maintenance items"
        case 1: return "1 urgent item needs landlord approval"
        default: return "\(entry.urgentMaintenanceCount) urgent items need landlord approval"
        }
    }

    /// Sydney time, e.g. "11:15 am" or "11:15".
    private func timeText(_ date: Date, withAmPm: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        formatter.dateFormat = withAmPm ? "h:mm a" : "h:mm"
        return formatter.string(from: date)
    }
}

#Preview(as: .systemSmall) {
    RoutineReadyWidget()
} timeline: {
    NextInspectionProvider.sampleEntry
    NextInspectionEntry(date: Date(), inspection: nil, urgentMaintenanceCount: 0, hasSnapshot: true)
}

#Preview(as: .systemMedium) {
    RoutineReadyWidget()
} timeline: {
    NextInspectionProvider.sampleEntry
}

#Preview(as: .accessoryRectangular) {
    RoutineReadyWidget()
} timeline: {
    NextInspectionProvider.sampleEntry
}
