import Foundation

/// Cancels a booked routine inspection. A cancelled inspection no longer counts toward the
/// 4-in-12-months limit, so the tenant's allowance is freed up straight away.
struct CancelRoutineInspection {
    let inspections: InspectionRepository
    let widgetSnapshot: WidgetSnapshotWriting

    func execute(inspectionID: UUID) throws {
        guard var inspection = try inspections.inspection(withID: inspectionID) else {
            throw InspectionCancellationError.inspectionNotFound
        }
        guard inspection.status != .completed else {
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
        case .alreadyCompleted: "A completed inspection can't be cancelled."
        case .inspectionNotFound: "This inspection is no longer in your diary."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .alreadyCompleted: "Its condition report stays on the property's history."
        case .inspectionNotFound: "Refresh the property's page and try again."
        }
    }
}
