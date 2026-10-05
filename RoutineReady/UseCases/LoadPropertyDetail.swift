import Foundation

struct PropertyDetail: Equatable {
    let property: Property
    /// Newest first.
    let inspectionHistory: [RoutineInspection]
    /// Non-cancelled inspections in the 12 months up to now, against `RoutineInspectionRules.annualLimit`.
    let inspectionsUsedInLast12Months: Int
}

/// A property with its inspection history and how much of the annual routine inspection allowance is used.
/// The allowance is queried with the same annual limit query that `ScheduleRoutineInspection` enforces.
struct LoadPropertyDetail {
    let properties: PropertyRepository
    let inspections: InspectionRepository
    let clock: DateProviding
    var calendar: Calendar = .sydney

    func execute(propertyID: UUID) throws -> PropertyDetail {
        guard let property = try properties.property(withID: propertyID) else {
            throw PropertyDetailError.propertyNotFound
        }
        let now = clock.now
        let used = try inspections.inspectionsCountingTowardAnnualLimit(
            propertyID: propertyID,
            from: RoutineInspectionRules.annualWindowStart(endingAt: now, calendar: calendar),
            through: now
        )
        return PropertyDetail(
            property: property,
            inspectionHistory: try inspections.inspections(forPropertyID: propertyID),
            inspectionsUsedInLast12Months: used.count
        )
    }
}

enum PropertyDetailError: LocalizedError, Equatable {
    case propertyNotFound

    var errorDescription: String? { "This property is no longer in your portfolio." }
    var recoverySuggestion: String? { "Go back to the portfolio and choose another property." }
}
