import Foundation

// Fake repository for the unit tests and SwiftUI previews.
// Each filter here matches the predicate in CoreDataInspectionRepository.
class InMemoryInspectionRepository: InspectionRepository {
    private(set) var inspections: [RoutineInspection]
    private(set) var maintenanceItems: [MaintenanceItem]

    init(inspections: [RoutineInspection] = [], maintenanceItems: [MaintenanceItem] = []) {
        self.inspections = inspections
        self.maintenanceItems = maintenanceItems
    }

    func inspection(withID id: UUID) throws -> RoutineInspection? {
        return inspections.first { $0.id == id }
    }

    func inspections(forPropertyID id: UUID) throws -> [RoutineInspection] {
        let forProperty = inspections.filter { $0.propertyID == id }
        return forProperty.sorted { $0.scheduledAt > $1.scheduledAt }
    }

    func scheduledInspections(from start: Date, before end: Date) throws -> [RoutineInspection] {
        let matching = inspections.filter { inspection in
            inspection.status == .scheduled && inspection.scheduledAt >= start && inspection.scheduledAt < end
        }
        return matching.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    func inspectionsCountingTowardAnnualLimit(propertyID: UUID, from start: Date, through end: Date) throws -> [RoutineInspection] {
        let matching = inspections.filter { inspection in
            inspection.propertyID == propertyID
                && inspection.status != .cancelled
                && inspection.scheduledAt >= start
                && inspection.scheduledAt <= end
        }
        return matching.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    func save(_ inspection: RoutineInspection) throws {
        inspections.removeAll { $0.id == inspection.id }
        inspections.append(inspection)
    }

    func maintenanceItem(withID id: UUID) throws -> MaintenanceItem? {
        return maintenanceItems.first { $0.id == id }
    }

    func maintenanceItems(forInspectionID id: UUID) throws -> [MaintenanceItem] {
        let forInspection = maintenanceItems.filter { $0.inspectionID == id }
        return forInspection.sorted { $0.loggedAt < $1.loggedAt }
    }

    func urgentUnresolvedMaintenanceItems() throws -> [MaintenanceItem] {
        return maintenanceItems.filter { $0.severity == .urgent && !$0.isResolved }
    }

    func save(_ item: MaintenanceItem) throws {
        maintenanceItems.removeAll { $0.id == item.id }
        maintenanceItems.append(item)
    }
}
