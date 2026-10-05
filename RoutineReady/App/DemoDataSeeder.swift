import Foundation

/// Fills an empty portfolio with realistic demo data on first launch, so every screen and the widget
/// have something to show. It writes straight to the repositories: the history is made up to fit the
/// NSW rules, so it doesn't go through `ScheduleRoutineInspection` (which would reject past dates).
struct DemoDataSeeder {
    let properties: PropertyRepository
    let inspections: InspectionRepository
    let clock: DateProviding
    var calendar: Calendar = .sydney

    func seedIfEmpty() {
        do {
            if try properties.allProperties().isEmpty {
                try seed()
            }
        } catch {
            print("Could not add demo data: \(error)")
        }
    }

    private func seed() throws {
        let roseSt = try addProperty("14 Rose St", "Yagoona", tenant: "Mia Nguyen", landlord: "Peter Haddad")
        let kitchenerPde = try addProperty("3/27 Kitchener Pde", "Bankstown", tenant: "Omar Khalil", landlord: "Linda Tran")
        let lyleSt = try addProperty("8 Lyle St", "Bass Hill", tenant: "Jack and Ella Brown", landlord: "Sandra Costa")
        let wattleSt = try addProperty("21 Wattle St", "Punchbowl", tenant: "Priya Sharma", landlord: "George Makris")
        let cairdsAve = try addProperty("5/10 Cairds Ave", "Bankstown", tenant: "Daniel Lee", landlord: "Fatima Rahman")
        _ = try addProperty("77 Rookwood Rd", "Yagoona", tenant: "Sione Taufa", landlord: "Helen Kovac")

        // Today's run sheet. If today is a Sunday or public holiday, these tenants agreed in writing.
        let todayIsRestricted = calendar.component(.weekday, from: clock.now) == 1
            || GazettedNSWPublicHolidays().holidayName(on: clock.now) != nil
        try addInspection(kitchenerPde, at: today(9, 0), consent: todayIsRestricted)
        try addInspection(roseSt, at: today(11, 15), consent: todayIsRestricted)
        try addInspection(wattleSt, at: today(14, 30), consent: todayIsRestricted)
        try addInspection(lyleSt, at: today(16, 45), consent: todayIsRestricted)
        // Late in the day there would be nothing left for the widget, so add an after-work visit the tenant asked for.
        let inAnHour = clock.now.addingTimeInterval(60 * 60)
        if inAnHour > today(16, 45) && calendar.isDate(inAnHour, inSameDayAs: clock.now) {
            try addInspection(cairdsAve, at: inAnHour, consent: true)
        }

        // History: 14 Rose St has used 3 of its 4 inspections in the last 12 months, so a 5th booking is refused.
        let roseJanuary = try addInspection(roseSt, at: weekday(daysAgo: 270), status: .completed)
        try addInspection(roseSt, at: weekday(daysAgo: 180), status: .completed)
        let roseJuly = try addInspection(roseSt, at: weekday(daysAgo: 90), status: .completed)
        try addInspection(kitchenerPde, at: weekday(daysAgo: 120), status: .completed)
        try addInspection(kitchenerPde, at: weekday(daysAgo: 30), status: .cancelled)
        try addInspection(cairdsAve, at: weekday(daysAgo: 200), status: .completed)

        try addItem(to: roseJuly, room: "Bathroom", "Exposed wiring behind vanity", .urgent)
        try addItem(to: roseJuly, room: "Laundry", "Tap drips when turned off", .routine)
        try addItem(to: roseJanuary, room: "Kitchen", "Cooktop not igniting", .urgent, resolved: true)
        try addItem(to: roseJanuary, room: "Kitchen", "Gas smell near oven", .urgent)
    }

    private func addProperty(_ address: String, _ suburb: String, tenant: String, landlord: String) throws -> Property {
        let property = Property(id: UUID(), address: address, suburb: suburb, tenantName: tenant,
                                landlordName: landlord, tenancyStartDate: weekday(daysAgo: 400))
        try properties.add(property)
        return property
    }

    @discardableResult
    private func addInspection(_ property: Property, at date: Date, status: InspectionStatus = .scheduled, consent: Bool = false) throws -> RoutineInspection {
        let inspection = RoutineInspection(
            id: UUID(),
            propertyID: property.id,
            scheduledAt: date,
            noticeServedAt: calendar.date(byAdding: .day, value: -10, to: date)!,
            status: status,
            conditionSummary: status == .completed ? "Clean and well kept. Minor wear to carpets." : nil,
            completedAt: status == .completed ? date.addingTimeInterval(45 * 60) : nil,
            tenantConsentRecorded: consent
        )
        try inspections.save(inspection)
        return inspection
    }

    private func addItem(to inspection: RoutineInspection, room: String, _ description: String, _ severity: MaintenanceSeverity, resolved: Bool = false) throws {
        let item = MaintenanceItem(id: UUID(), inspectionID: inspection.id, room: room, itemDescription: description,
                                   severity: severity, isResolved: resolved, photoFilename: nil, loggedAt: inspection.scheduledAt)
        try inspections.save(item)
    }

    private func today(_ hour: Int, _ minute: Int) -> Date {
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: clock.now)!
    }

    /// 10:00 am about `daysAgo` days ago, moved to Monday if it lands on a Sunday.
    private func weekday(daysAgo: Int) -> Date {
        var date = calendar.date(byAdding: .day, value: -daysAgo, to: today(10, 0))!
        if calendar.component(.weekday, from: date) == 1 {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return date
    }
}
