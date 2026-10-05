import Foundation

/// Records a defect found during a routine inspection. Every item needs a description; an urgent item also
/// needs its room, so the tradesperson sent out can find it without calling the tenant.
struct LogMaintenanceItem {
    let inspections: InspectionRepository
    let clock: DateProviding
    let widgetSnapshot: WidgetSnapshotWriting

    @discardableResult
    func execute(inspectionID: UUID, room: String, description: String, severity: MaintenanceSeverity, photoFilename: String? = nil) throws -> MaintenanceItem {
        guard let inspection = try inspections.inspection(withID: inspectionID) else {
            throw MaintenanceLoggingError.inspectionNotFound
        }
        guard inspection.status != .cancelled else {
            throw MaintenanceLoggingError.inspectionCancelled
        }
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let room = room.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !description.isEmpty else {
            throw MaintenanceLoggingError.missingDescription
        }
        guard severity != .urgent || !room.isEmpty else {
            throw MaintenanceLoggingError.urgentItemNeedsRoom
        }

        let item = MaintenanceItem(
            id: UUID(),
            inspectionID: inspectionID,
            room: room,
            itemDescription: description,
            severity: severity,
            isResolved: false,
            photoFilename: photoFilename,
            loggedAt: clock.now
        )
        try inspections.save(item)
        widgetSnapshot.refreshWidgetSnapshot()
        return item
    }
}

enum MaintenanceLoggingError: LocalizedError, Equatable {
    case missingDescription
    case inspectionCancelled
    case urgentItemNeedsRoom
    case inspectionNotFound

    var errorDescription: String? {
        switch self {
        case .missingDescription: "Describe the maintenance item before saving it."
        case .inspectionCancelled: "This inspection was cancelled, so items can't be logged against it."
        case .urgentItemNeedsRoom: "Say which room this is in so the tradesperson can find it."
        case .inspectionNotFound: "This inspection is no longer in your diary."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingDescription: "A few words is enough, e.g. \"Leaking tap under kitchen sink\"."
        case .inspectionCancelled: "Log it against the property's next routine inspection instead."
        case .urgentItemNeedsRoom: "Enter the room, e.g. \"Bathroom\" or \"Kitchen\"."
        case .inspectionNotFound: "Go back to today's run sheet and choose the inspection again."
        }
    }
}
