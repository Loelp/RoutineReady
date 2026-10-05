import Foundation

/// Cancels a booked inspection. Cancelled inspections don't count toward the 4 per year limit,
/// so this frees up a spot for that property.
struct CancelRoutineInspection {
    let inspections: InspectionRepository
    let widgetSnapshot: WidgetSnapshotWriting

    func execute(inspectionID: UUID) throws {
        guard var inspection = try inspections.inspection(withID: inspectionID) else {
            throw InspectionCancellationError.inspectionNotFound
        }
        if inspection.status == .completed {
            throw InspectionCancellationError.alreadyCompleted
        }

        inspection.status = .cancelled
        try inspections.save(inspection)
        widgetSnapshot.refreshWidgetSnapshot()
    }
}

enum InspectionCancellationError: LocalizedError, Equatable {
    case alreadyCompleted
    case inspectionNotFound

    var errorDescription: String? {
        switch self {
        case .alreadyCompleted:
            return "You can't cancel an inspection that's already been completed."
        case .inspectionNotFound:
            return "This inspection couldn't be found."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .alreadyCompleted:
            return "Its condition report stays in the property's history."
        case .inspectionNotFound:
            return "Go back and open the property again."
        }
    }
}
