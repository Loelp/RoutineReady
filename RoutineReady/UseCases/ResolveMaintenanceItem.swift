import Foundation

/// Marks a maintenance item as fixed, removing it from the urgent backlog shown on the widget.
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

    var errorDescription: String? { "This maintenance item no longer exists." }
    var recoverySuggestion: String? { "Reopen the inspection to see its current maintenance items." }
}
