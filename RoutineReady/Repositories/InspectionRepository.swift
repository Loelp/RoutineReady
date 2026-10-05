import Foundation

/// Routine inspections and the maintenance items logged during them.
protocol InspectionRepository {
    func inspection(withID id: UUID) throws -> RoutineInspection?
    /// Every inspection of a property, newest first.
    func inspections(forPropertyID id: UUID) throws -> [RoutineInspection]
    /// Run sheet query: `status == "scheduled" AND scheduledAt >= start AND scheduledAt < end`, sorted by `scheduledAt`.
    func scheduledInspections(from start: Date, before end: Date) throws -> [RoutineInspection]
    /// Annual limit query: `property.id == id AND status != "cancelled" AND scheduledAt >= start AND scheduledAt <= end`,
    /// oldest first.
    func inspectionsCountingTowardAnnualLimit(propertyID: UUID, from start: Date, through end: Date) throws -> [RoutineInspection]
    /// Inserts or updates.
    func save(_ inspection: RoutineInspection) throws

    func maintenanceItem(withID id: UUID) throws -> MaintenanceItem?
    /// Items logged during one inspection, oldest first.
    func maintenanceItems(forInspectionID id: UUID) throws -> [MaintenanceItem]
    /// Urgent backlog query: `severity == "urgent" AND isResolved == NO`.
    func urgentUnresolvedMaintenanceItems() throws -> [MaintenanceItem]
    /// Inserts or updates.
    func save(_ item: MaintenanceItem) throws
}
