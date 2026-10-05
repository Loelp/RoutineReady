import CoreData

class CoreDataInspectionRepository: InspectionRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: Routine inspections

    func inspection(withID id: UUID) throws -> RoutineInspection? {
        return try findInspectionEntity(id: id)?.toDomain()
    }

    func inspections(forPropertyID id: UUID) throws -> [RoutineInspection] {
        let request = RoutineInspectionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "property.id == %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: false)]
        return try context.fetch(request).map { $0.toDomain() }
    }

    // used for today's run sheet
    func scheduledInspections(from start: Date, before end: Date) throws -> [RoutineInspection] {
        let request = RoutineInspectionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "status == %@ AND scheduledAt >= %@ AND scheduledAt < %@",
            InspectionStatus.scheduled.rawValue, start as NSDate, end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try context.fetch(request).map { $0.toDomain() }
    }

    // used for the 4 per year check (no counter is stored, it's counted each time)
    func inspectionsCountingTowardAnnualLimit(propertyID: UUID, from start: Date, through end: Date) throws -> [RoutineInspection] {
        let request = RoutineInspectionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "property.id == %@ AND status != %@ AND scheduledAt >= %@ AND scheduledAt <= %@",
            propertyID as CVarArg, InspectionStatus.cancelled.rawValue, start as NSDate, end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try context.fetch(request).map { $0.toDomain() }
    }

    func save(_ inspection: RoutineInspection) throws {
        // update the existing one if there is one, otherwise make a new one
        var entity = try findInspectionEntity(id: inspection.id)
        if entity == nil {
            guard let property = try findPropertyEntity(id: inspection.propertyID) else {
                throw PersistenceError.couldNotSave
            }
            entity = RoutineInspectionEntity(context: context)
            entity?.property = property
        }
        entity?.update(from: inspection)
        try context.saveChanges()
    }

    // MARK: Maintenance items

    func maintenanceItem(withID id: UUID) throws -> MaintenanceItem? {
        return try findItemEntity(id: id)?.toDomain()
    }

    func maintenanceItems(forInspectionID id: UUID) throws -> [MaintenanceItem] {
        let request = MaintenanceItemEntity.fetchRequest()
        request.predicate = NSPredicate(format: "inspection.id == %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "loggedAt", ascending: true)]
        return try context.fetch(request).map { $0.toDomain() }
    }

    // the urgent count shown on the widget
    func urgentUnresolvedMaintenanceItems() throws -> [MaintenanceItem] {
        let request = MaintenanceItemEntity.fetchRequest()
        request.predicate = NSPredicate(format: "severity == %@ AND isResolved == NO", MaintenanceSeverity.urgent.rawValue)
        return try context.fetch(request).map { $0.toDomain() }
    }

    func save(_ item: MaintenanceItem) throws {
        var entity = try findItemEntity(id: item.id)
        if entity == nil {
            guard let inspection = try findInspectionEntity(id: item.inspectionID) else {
                throw PersistenceError.couldNotSave
            }
            entity = MaintenanceItemEntity(context: context)
            entity?.inspection = inspection
        }
        entity?.update(from: item)
        try context.saveChanges()
    }

    // MARK: Lookups by id

    private func findPropertyEntity(id: UUID) throws -> PropertyEntity? {
        let request = PropertyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func findInspectionEntity(id: UUID) throws -> RoutineInspectionEntity? {
        let request = RoutineInspectionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func findItemEntity(id: UUID) throws -> MaintenanceItemEntity? {
        let request = MaintenanceItemEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
