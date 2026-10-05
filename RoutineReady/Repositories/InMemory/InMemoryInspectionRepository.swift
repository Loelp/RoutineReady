import Foundation

/// Test and SwiftUI preview stand-in for `CoreDataInspectionRepository`.
/// Each query mirrors the Core Data predicate documented on `InspectionRepository`.
final class InMemoryInspectionRepository: InspectionRepository {
    private(set) var inspections: [RoutineInspection]
    private(set) var maintenanceItems: [MaintenanceItem]

    init(inspections: [RoutineInspection] = [], maintenanceItems: [MaintenanceItem] = []) {
        self.inspections = inspections
        self.maintenanceItems = maintenanceItems
    }

    func inspection(withID id: UUID) throws -> RoutineInspection? {
        inspections.first { $0.id == id }
    }

    func inspections(forPropertyID id: UUID) throws -> [RoutineInspection] {
        inspections.filter { $0.propertyID == id }.sorted { $0.scheduledAt > $1.scheduledAt }
    }

    func scheduledInspections(from start: Date, before end: Date) throws -> [RoutineInspection] {
        inspections
            .filter { $0.status == .scheduled && $0.scheduledAt >= start && $0.scheduledAt < end }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    func inspectionsCountingTowardAnnualLimit(propertyID: UUID, from start: Date, through end: Date) throws -> [RoutineInspection] {
        inspections
            .filter { $0.propertyID == propertyID && $0.status != .cancelled && $0.scheduledAt >= start && $0.scheduledAt <= end }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    func save(_ inspection: RoutineInspection) throws {
        inspections.removeAll { $0.id == inspection.id }
        inspections.append(inspection)
    }

    func maintenanceItem(withID id: UUID) throws -> MaintenanceItem? {
        maintenanceItems.first { $0.id == id }
    }

    func maintenanceItems(forInspectionID id: UUID) throws -> [MaintenanceItem] {
        maintenanceItems.filter { $0.inspectionID == id }.sorted { $0.loggedAt < $1.loggedAt }
    }

    func urgentUnresolvedMaintenanceItems() throws -> [MaintenanceItem] {
        maintenanceItems.filter { $0.severity == .urgent && !$0.isResolved }
    }

    func save(_ item: MaintenanceItem) throws {
        maintenanceItems.removeAll { $0.id == item.id }
        maintenanceItems.append(item)
    }
}
