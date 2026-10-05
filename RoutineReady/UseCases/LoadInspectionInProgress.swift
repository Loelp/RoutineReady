import Foundation

struct InspectionInProgress: Equatable {
    let inspection: RoutineInspection
    let property: Property
    let maintenanceItems: [MaintenanceItem]
}

/// The inspection being walked through, with its property and the maintenance items logged so far.
struct LoadInspectionInProgress {
    let properties: PropertyRepository
    let inspections: InspectionRepository

    func execute(inspectionID: UUID) throws -> InspectionInProgress {
        guard let inspection = try inspections.inspection(withID: inspectionID),
              let property = try properties.property(withID: inspection.propertyID) else {
            throw InspectionLookupError.inspectionNotFound
        }
        return InspectionInProgress(
            inspection: inspection,
            property: property,
            maintenanceItems: try inspections.maintenanceItems(forInspectionID: inspectionID)
        )
    }
}

enum InspectionLookupError: LocalizedError, Equatable {
    case inspectionNotFound

    var errorDescription: String? { "This inspection is no longer in your diary." }
    var recoverySuggestion: String? { "Go back to today's run sheet and choose the inspection again." }
}
