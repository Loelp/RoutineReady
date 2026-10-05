import Foundation

struct InspectionInProgress: Equatable {
    let inspection: RoutineInspection
    let property: Property
    let maintenanceItems: [MaintenanceItem]
}

/// Loads an inspection with its property and the maintenance items logged so far.
struct LoadInspectionInProgress {
    let properties: PropertyRepository
    let inspections: InspectionRepository

    func execute(inspectionID: UUID) throws -> InspectionInProgress {
        guard let inspection = try inspections.inspection(withID: inspectionID) else {
            throw InspectionLookupError.inspectionNotFound
        }
        guard let property = try properties.property(withID: inspection.propertyID) else {
            throw InspectionLookupError.inspectionNotFound
        }

        let items = try inspections.maintenanceItems(forInspectionID: inspectionID)
        return InspectionInProgress(inspection: inspection, property: property, maintenanceItems: items)
    }
}

enum InspectionLookupError: LocalizedError, Equatable {
    case inspectionNotFound

    var errorDescription: String? {
        return "This inspection couldn't be found."
    }

    var recoverySuggestion: String? {
        return "Go back to today's run sheet and open it again."
    }
}
