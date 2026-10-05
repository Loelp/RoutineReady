import Foundation

enum InspectionStatus: String, CaseIterable {
    case scheduled, completed, cancelled
}

// A routine ("general") inspection of a property
struct RoutineInspection: Identifiable, Equatable, Hashable {
    let id: UUID
    let propertyID: UUID
    var scheduledAt: Date
    var noticeServedAt: Date
    var status: InspectionStatus
    var conditionSummary: String?
    var completedAt: Date?
    // tenant agreed in writing - skips the notice/day/time rules but NOT the 4 per year limit
    var tenantConsentRecorded: Bool
}
