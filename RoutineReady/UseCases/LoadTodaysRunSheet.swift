import Foundation

// One stop on the run sheet - the inspection plus the property it's at
struct RunSheetStop: Identifiable, Equatable {
    let inspection: RoutineInspection
    let property: Property

    var id: UUID {
        return inspection.id
    }
}

/// Today's scheduled inspections (Sydney time) in time order, so the property manager
/// can drive to them one after another.
/// This only reads data, so there's no error enum - the only thing that can go wrong is the database.
struct LoadTodaysRunSheet {
    let properties: PropertyRepository
    let inspections: InspectionRepository
    let clock: DateProviding
    var calendar: Calendar = .sydney

    func execute() throws -> [RunSheetStop] {
        let startOfToday = calendar.startOfDay(for: clock.now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        let todaysInspections = try inspections.scheduledInspections(from: startOfToday, before: startOfTomorrow)

        var stops: [RunSheetStop] = []
        for inspection in todaysInspections {
            if let property = try properties.property(withID: inspection.propertyID) {
                stops.append(RunSheetStop(inspection: inspection, property: property))
            }
        }
        return stops
    }
}
