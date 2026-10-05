import CoreData

// Core Data class for Property. Codegen is set to Manual/None in the model so this is written by hand.
@objc(PropertyEntity)
class PropertyEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var address: String
    @NSManaged var suburb: String
    @NSManaged var tenantName: String
    @NSManaged var landlordName: String
    @NSManaged var tenancyStartDate: Date
    @NSManaged var inspections: Set<RoutineInspectionEntity>

    @nonobjc class func fetchRequest() -> NSFetchRequest<PropertyEntity> {
        return NSFetchRequest<PropertyEntity>(entityName: "PropertyEntity")
    }

    // convert to the plain struct the rest of the app uses
    func toDomain() -> Property {
        return Property(
            id: id,
            address: address,
            suburb: suburb,
            tenantName: tenantName,
            landlordName: landlordName,
            tenancyStartDate: tenancyStartDate
        )
    }

    func update(from property: Property) {
        id = property.id
        address = property.address
        suburb = property.suburb
        tenantName = property.tenantName
        landlordName = property.landlordName
        tenancyStartDate = property.tenancyStartDate
    }
}
