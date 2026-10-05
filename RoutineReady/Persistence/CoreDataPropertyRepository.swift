import CoreData

class CoreDataPropertyRepository: PropertyRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func allProperties() throws -> [Property] {
        let request = PropertyEntity.fetchRequest()
        request.sortDescriptors = sortBySuburbThenAddress
        return try context.fetch(request).map { $0.toDomain() }
    }

    func properties(matching text: String) throws -> [Property] {
        let request = PropertyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "address CONTAINS[cd] %@ OR suburb CONTAINS[cd] %@", text, text)
        request.sortDescriptors = sortBySuburbThenAddress
        return try context.fetch(request).map { $0.toDomain() }
    }

    func property(withID id: UUID) throws -> Property? {
        return try findEntity(id: id)?.toDomain()
    }

    func add(_ property: Property) throws {
        let entity = PropertyEntity(context: context)
        entity.update(from: property)
        try context.saveChanges()
    }

    private func findEntity(id: UUID) throws -> PropertyEntity? {
        let request = PropertyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private var sortBySuburbThenAddress: [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "suburb", ascending: true),
            NSSortDescriptor(key: "address", ascending: true)
        ]
    }
}
