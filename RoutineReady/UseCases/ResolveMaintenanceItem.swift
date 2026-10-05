import Foundation

/// Marks a maintenance item as fixed. This takes it off the urgent count on the widget.
struct ResolveMaintenanceItem {
    let inspections: InspectionRepository
    let widgetSnapshot: WidgetSnapshotWriting

    func execute(itemID: UUID) throws {
        guard var item = try inspections.maintenanceItem(withID: itemID) else {
            throw MaintenanceResolutionError.maintenanceItemNotFound
        }
        item.isResolved = true
        try inspections.save(item)
        widgetSnapshot.refreshWidgetSnapshot()
    }
}

enum MaintenanceResolutionError: LocalizedError, Equatable {
    case maintenanceItemNotFound

    var errorDescription: String? {
        return "This maintenance item couldn't be found."
    }

    var recoverySuggestion: String? {
        return "Go back and open the inspection again."
    }
}
