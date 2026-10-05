import Foundation

enum MaintenanceSeverity: String, CaseIterable, Identifiable {
    case urgent, routine, cosmetic

    var id: Self { self }
    var displayName: String { rawValue.capitalized }
}

/// A defect found during a routine inspection, for the landlord to approve and a tradesperson to fix.
struct MaintenanceItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let inspectionID: UUID
    var room: String
    var itemDescription: String
    var severity: MaintenanceSeverity
    var isResolved: Bool
    /// File name inside the App Group `Photos/` folder.
    var photoFilename: String?
    var loggedAt: Date
}
