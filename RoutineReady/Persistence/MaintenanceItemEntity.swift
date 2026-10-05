import CoreData

/// Core Data storage for a `MaintenanceItem`. Written by hand (codegen is Manual/None).
@objc(MaintenanceItemEntity)
class MaintenanceItemEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var room: String
    @NSManaged var itemDescription: String
    /// "urgent", "routine" or "cosmetic"
    @NSManaged var severity: String
    @NSManaged var isResolved: Bool
    @NSManaged var photoFilename: String?
    @NSManaged var loggedAt: Date
    @NSManaged var inspection: RoutineInspectionEntity

    @nonobjc class func fetchRequest() -> NSFetchRequest<MaintenanceItemEntity> {
        return NSFetchRequest<MaintenanceItemEntity>(entityName: "MaintenanceItemEntity")
    }

    func toDomain() -> MaintenanceItem {
        return MaintenanceItem(
            id: id,
            inspectionID: inspection.id,
            room: room,
            itemDescription: itemDescription,
            severity: MaintenanceSeverity(rawValue: severity) ?? .routine,
            isResolved: isResolved,
            photoFilename: photoFilename,
            loggedAt: loggedAt
        )
    }

    func update(from item: MaintenanceItem) {
        id = item.id
        room = item.room
        itemDescription = item.itemDescription
        severity = item.severity.rawValue
        isResolved = item.isResolved
        photoFilename = item.photoFilename
        loggedAt = item.loggedAt
    }
}
