import Foundation

/// Saves a maintenance item found during an inspection. It always needs a description,
/// and urgent ones also need a room so the tradesperson knows where to go.
struct LogMaintenanceItem {
    let inspections: InspectionRepository
    let clock: DateProviding
    let widgetSnapshot: WidgetSnapshotWriting

    func execute(inspectionID: UUID, room: String, description: String, severity: MaintenanceSeverity, photoFilename: String? = nil) throws -> MaintenanceItem {
        guard let inspection = try inspections.inspection(withID: inspectionID) else {
            throw MaintenanceLoggingError.inspectionNotFound
        }
        if inspection.status == .cancelled {
            throw MaintenanceLoggingError.inspectionCancelled
        }

        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanRoom = room.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanDescription.isEmpty {
            throw MaintenanceLoggingError.missingDescription
        }
        if severity == .urgent && cleanRoom.isEmpty {
            throw MaintenanceLoggingError.urgentItemNeedsRoom
        }

        let item = MaintenanceItem(
            id: UUID(),
            inspectionID: inspectionID,
            room: cleanRoom,
            itemDescription: cleanDescription,
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
        case .missingDescription:
            return "Describe the maintenance item before saving it."
        case .inspectionCancelled:
            return "This inspection was cancelled, so you can't add items to it."
        case .urgentItemNeedsRoom:
            return "Say which room this is in so the tradesperson can find it."
        case .inspectionNotFound:
            return "This inspection couldn't be found."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingDescription:
            return "A few words is enough, e.g. \"Leaking tap under kitchen sink\"."
        case .inspectionCancelled:
            return "Add it to the property's next inspection instead."
        case .urgentItemNeedsRoom:
            return "Type the room, e.g. \"Bathroom\" or \"Kitchen\"."
        case .inspectionNotFound:
            return "Go back to today's run sheet and open it again."
        }
    }
}
