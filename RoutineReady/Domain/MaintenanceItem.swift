import Foundation

enum MaintenanceSeverity: String, CaseIterable, Identifiable {
    case urgent, routine, cosmetic

    var id: MaintenanceSeverity { return self }

    var displayName: String {
        return rawValue.capitalized
    }
}

// Something found during an inspection that needs fixing
struct MaintenanceItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let inspectionID: UUID
    var room: String
    var itemDescription: String
    var severity: MaintenanceSeverity
    var isResolved: Bool
    var photoFilename: String?   // file name in the App Group Photos folder
    var loggedAt: Date
}
