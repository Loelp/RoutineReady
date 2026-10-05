import CoreData

// Core Data class for RoutineInspection. Codegen is set to Manual/None in the model so this is written by hand.
@objc(RoutineInspectionEntity)
class RoutineInspectionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var scheduledAt: Date
    @NSManaged var noticeServedAt: Date
    @NSManaged var status: String   // "scheduled", "completed" or "cancelled"
    @NSManaged var conditionSummary: String?
    @NSManaged var completedAt: Date?
    @NSManaged var tenantConsentRecorded: Bool
    @NSManaged var property: PropertyEntity
    @NSManaged var maintenanceItems: Set<MaintenanceItemEntity>

    @nonobjc class func fetchRequest() -> NSFetchRequest<RoutineInspectionEntity> {
        return NSFetchRequest<RoutineInspectionEntity>(entityName: "RoutineInspectionEntity")
    }

    func toDomain() -> RoutineInspection {
        return RoutineInspection(
            id: id,
            propertyID: property.id,
            scheduledAt: scheduledAt,
            noticeServedAt: noticeServedAt,
            status: InspectionStatus(rawValue: status) ?? .scheduled,
            conditionSummary: conditionSummary,
            completedAt: completedAt,
            tenantConsentRecorded: tenantConsentRecorded
        )
    }

    func update(from inspection: RoutineInspection) {
        id = inspection.id
        scheduledAt = inspection.scheduledAt
        noticeServedAt = inspection.noticeServedAt
        status = inspection.status.rawValue
        conditionSummary = inspection.conditionSummary
        completedAt = inspection.completedAt
        tenantConsentRecorded = inspection.tenantConsentRecorded
    }
}
