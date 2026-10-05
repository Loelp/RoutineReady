import Foundation

/// Books a routine inspection only when NSW law allows it (Residential Tenancies Act 2010 s 55):
/// 1. at least 7 days written notice, counted in calendar days in Sydney;
/// 2. no more than 4 non-cancelled inspections in the rolling 12 months up to and including the proposed date;
/// 3. not on a Sunday or NSW public holiday;
/// 4. starting between 08:00 and 19:59.
/// If the tenant has agreed in writing, rules 1, 3 and 4 are waived but rule 2 still applies.
struct ScheduleRoutineInspection {
    let properties: PropertyRepository
    let inspections: InspectionRepository
    let publicHolidays: NSWPublicHolidays
    let clock: DateProviding
    let widgetSnapshot: WidgetSnapshotWriting
    var calendar: Calendar = .sydney

    @discardableResult
    func execute(propertyID: UUID, scheduledAt: Date, noticeServedAt: Date, tenantConsentRecorded: Bool) throws -> RoutineInspection {
        guard try properties.property(withID: propertyID) != nil else {
            throw InspectionSchedulingError.propertyNotFound
        }
        guard scheduledAt > clock.now else {
            throw InspectionSchedulingError.inspectionInThePast
        }
        if !tenantConsentRecorded {
            try checkNotice(servedAt: noticeServedAt, before: scheduledAt)
            try checkDay(of: scheduledAt)
            try checkStartTime(of: scheduledAt)
        }
        try checkAnnualLimit(propertyID: propertyID, proposedDate: scheduledAt)

        let inspection = RoutineInspection(
            id: UUID(),
            propertyID: propertyID,
            scheduledAt: scheduledAt,
            noticeServedAt: noticeServedAt,
            status: .scheduled,
            tenantConsentRecorded: tenantConsentRecorded
        )
        try inspections.save(inspection)
        widgetSnapshot.refreshWidgetSnapshot()
        return inspection
    }

    private func checkNotice(servedAt noticeServedAt: Date, before scheduledAt: Date) throws {
        let noticeDay = calendar.startOfDay(for: noticeServedAt)
        let days = calendar.dateComponents([.day], from: noticeDay, to: calendar.startOfDay(for: scheduledAt)).day!
        guard days >= RoutineInspectionRules.minimumNoticeDays else {
            throw InspectionSchedulingError.insufficientNotice(earliestLawfulDate: earliestLawfulDate(noticeDay: noticeDay))
        }
    }

    /// Seven days after the notice, moved past any Sunday or public holiday.
    private func earliestLawfulDate(noticeDay: Date) -> Date {
        var date = calendar.date(byAdding: .day, value: RoutineInspectionRules.minimumNoticeDays, to: noticeDay)!
        while isSunday(date) || publicHolidays.holidayName(on: date) != nil {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return date
    }

    private func checkDay(of scheduledAt: Date) throws {
        if let holidayName = publicHolidays.holidayName(on: scheduledAt) {
            throw InspectionSchedulingError.sundayOrPublicHoliday(holidayName: holidayName)
        }
        if isSunday(scheduledAt) {
            throw InspectionSchedulingError.sundayOrPublicHoliday(holidayName: nil)
        }
    }

    private func checkStartTime(of scheduledAt: Date) throws {
        guard RoutineInspectionRules.permittedStartHours.contains(calendar.component(.hour, from: scheduledAt)) else {
            throw InspectionSchedulingError.outsidePermittedHours
        }
    }

    /// Queries the window every time rather than keeping a counter, so cancellations and edits are always reflected.
    private func checkAnnualLimit(propertyID: UUID, proposedDate: Date) throws {
        let counted = try inspections.inspectionsCountingTowardAnnualLimit(
            propertyID: propertyID,
            from: RoutineInspectionRules.annualWindowStart(endingAt: proposedDate, calendar: calendar),
            through: proposedDate
        )
        guard counted.count >= RoutineInspectionRules.annualLimit else { return }
        // Booking becomes possible once enough of the oldest inspections are more than 12 months old.
        let mustLapse = counted[counted.count - RoutineInspectionRules.annualLimit]
        let lapsesAt = calendar.date(byAdding: .year, value: 1, to: mustLapse.scheduledAt)!
        throw InspectionSchedulingError.annualLimitReached(nextAvailableDate: lapsesAt)
    }

    private func isSunday(_ date: Date) -> Bool {
        calendar.component(.weekday, from: date) == 1
    }
}

enum InspectionSchedulingError: LocalizedError, Equatable {
    case insufficientNotice(earliestLawfulDate: Date)
    case annualLimitReached(nextAvailableDate: Date)
    case sundayOrPublicHoliday(holidayName: String?)
    case outsidePermittedHours
    case inspectionInThePast
    case propertyNotFound

    var errorDescription: String? {
        switch self {
        case .insufficientNotice(let earliestLawfulDate):
            "This tenant needs 7 days written notice. The earliest lawful date is \(earliestLawfulDate.inspectionDayText)."
        case .annualLimitReached:
            "This property has already had 4 routine inspections in the 12 months before this date, the most NSW law allows."
        case .sundayOrPublicHoliday(let holidayName?):
            "Routine inspections can't be held on \(holidayName), an NSW public holiday."
        case .sundayOrPublicHoliday(nil):
            "Routine inspections can't be held on a Sunday."
        case .outsidePermittedHours:
            "Routine inspections must start between 8:00 am and 8:00 pm."
        case .inspectionInThePast:
            "This time has already passed."
        case .propertyNotFound:
            "This property is no longer in your portfolio."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .insufficientNotice(let earliestLawfulDate):
            "Choose \(earliestLawfulDate.inspectionDayText) or later, or record the tenant's written agreement to an earlier time."
        case .annualLimitReached(let nextAvailableDate):
            "The next routine inspection can be booked after \(nextAvailableDate.inspectionTimeText) on \(nextAvailableDate.inspectionDayText), when the oldest of the four falls outside the 12 months."
        case .sundayOrPublicHoliday:
            "Pick a Monday to Saturday that isn't a public holiday, or record the tenant's written agreement to this day."
        case .outsidePermittedHours:
            "Choose a start time from 8:00 am to 7:59 pm, or record the tenant's written agreement to this time."
        case .inspectionInThePast:
            "Choose a date and time later than now."
        case .propertyNotFound:
            "Go back to the portfolio and choose the property again."
        }
    }
}
