import Foundation

// Inspections and the maintenance items logged during them.
// The comments show the predicate the Core Data version uses for each query.
protocol InspectionRepository {
    func inspection(withID id: UUID) throws -> RoutineInspection?

    // newest first
    func inspections(forPropertyID id: UUID) throws -> [RoutineInspection]

    // run sheet: status == "scheduled" AND scheduledAt >= start AND scheduledAt < end (sorted by time)
    func scheduledInspections(from start: Date, before end: Date) throws -> [RoutineInspection]

    // annual limit: property.id == id AND status != "cancelled" AND scheduledAt >= start AND scheduledAt <= end
    // (oldest first)
    func inspectionsCountingTowardAnnualLimit(propertyID: UUID, from start: Date, through end: Date) throws -> [RoutineInspection]

    // adds it, or updates it if it's already saved
    func save(_ inspection: RoutineInspection) throws

    func maintenanceItem(withID id: UUID) throws -> MaintenanceItem?

    // oldest first
    func maintenanceItems(forInspectionID id: UUID) throws -> [MaintenanceItem]

    // urgent backlog: severity == "urgent" AND isResolved == NO
    func urgentUnresolvedMaintenanceItems() throws -> [MaintenanceItem]

    // adds it, or updates it if it's already saved
    func save(_ item: MaintenanceItem) throws
}
