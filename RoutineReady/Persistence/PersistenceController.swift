import CoreData

/// Owns the Core Data stack. The store lives in the app's own container;
/// the widget and share extension never open it.
class PersistenceController {
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "RoutineReady")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Could not open the RoutineReady database: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var context: NSManagedObjectContext {
        return container.viewContext
    }
}

/// Thrown by the Core Data repositories when a change can't be written to the database.
enum PersistenceError: LocalizedError {
    case couldNotSave

    var errorDescription: String? {
        return "Your change couldn't be saved on this iPhone."
    }

    var recoverySuggestion: String? {
        return "Try again. If it keeps happening, check the iPhone has free storage and restart RoutineReady."
    }
}

extension NSManagedObjectContext {
    /// Saves, or undoes the unsaved changes and throws `PersistenceError.couldNotSave`.
    func saveChanges() throws {
        do {
            try save()
        } catch {
            rollback()
            throw PersistenceError.couldNotSave
        }
    }
}
