import Foundation

/// One stop on the property manager's day: a scheduled inspection and the property it is at.
struct RunSheetStop: Identifiable, Equatable {
    let inspection: RoutineInspection
    let property: Property

    var id: UUID { inspection.id }
}

/// Today's scheduled routine inspections (Sydney time), in the order the property manager will drive to them.
/// Read-only: the only failures are storage errors, so it has no business error enum.
struct LoadTodaysRunSheet {
    let properties: PropertyRepository
    let inspections: InspectionRepository
    let clock: DateProviding
    var calendar: Calendar = .sydney

    func execute() throws -> [RunSheetStop] {
        let startOfToday = calendar.startOfDay(for: clock.now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        return try inspections.scheduledInspections(from: startOfToday, before: startOfTomorrow).compactMap { inspection in
            try properties.property(withID: inspection.propertyID).map { RunSheetStop(inspection: inspection, property: $0) }
        }
    }
}
