import Foundation

enum InspectionStatus: String, CaseIterable {
    case scheduled, completed, cancelled
}

/// A routine ("general") inspection of a property, as limited by the Residential Tenancies Act 2010 (NSW) s 55.
struct RoutineInspection: Identifiable, Equatable, Hashable {
    let id: UUID
    let propertyID: UUID
    var scheduledAt: Date
    var noticeServedAt: Date
    var status: InspectionStatus
    var conditionSummary: String?
    var completedAt: Date?
    /// The tenant agreed in writing to this time, which waives the notice, day and hour rules.
    var tenantConsentRecorded: Bool
}
