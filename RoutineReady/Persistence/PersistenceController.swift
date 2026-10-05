import CoreData

// Sets up Core Data. The database is in the app's own container - the widget and
// share extension never open it (they only use the JSON files in the App Group).
class PersistenceController {
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "RoutineReady")
        container.loadPersistentStores { _, error in
            if let error = error {
                // nothing in the app works without the database, so just stop here
                fatalError("Could not open the RoutineReady database: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var context: NSManagedObjectContext {
        return container.viewContext
    }
}

// Thrown by the Core Data repositories when saving fails
enum PersistenceError: LocalizedError {
    case couldNotSave

    var errorDescription: String? {
        return "Your change couldn't be saved."
    }

    var recoverySuggestion: String? {
        return "Try again. If it keeps happening, check the phone has free storage and restart the app."
    }
}

extension NSManagedObjectContext {
    // save, and if it fails, undo the changes so the context isn't left half-saved
    func saveChanges() throws {
        do {
            try save()
        } catch {
            rollback()
            throw PersistenceError.couldNotSave
        }
    }
}
