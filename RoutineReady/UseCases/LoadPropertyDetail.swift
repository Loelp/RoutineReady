import Foundation

struct PropertyDetail: Equatable {
    let property: Property
    let inspectionHistory: [RoutineInspection]   // newest first
    let inspectionsUsedInLast12Months: Int       // out of RoutineInspectionRules.annualLimit
}

/// A property with its inspection history, and how many of its 4 inspections it has used
/// in the last 12 months. Uses the same annual limit query as ScheduleRoutineInspection
/// so the number on screen always matches what booking will allow.
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
        let windowStart = RoutineInspectionRules.annualWindowStart(endingAt: now, calendar: calendar)
        let used = try inspections.inspectionsCountingTowardAnnualLimit(propertyID: propertyID, from: windowStart, through: now)

        return PropertyDetail(
            property: property,
            inspectionHistory: try inspections.inspections(forPropertyID: propertyID),
            inspectionsUsedInLast12Months: used.count
        )
    }
}

enum PropertyDetailError: LocalizedError, Equatable {
    case propertyNotFound

    var errorDescription: String? {
        return "This property isn't in your portfolio any more."
    }

    var recoverySuggestion: String? {
        return "Go back to the portfolio and pick another property."
    }
}
