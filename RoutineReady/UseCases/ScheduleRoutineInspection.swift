import Foundation

/// Books a routine inspection, but only if it follows the NSW rules (Residential Tenancies Act 2010 s 55):
/// 1. at least 7 days written notice (counting calendar days in Sydney time)
/// 2. no more than 4 inspections (not counting cancelled ones) in the 12 months up to the inspection date
/// 3. not on a Sunday or NSW public holiday
/// 4. must start between 8:00 am and 7:59 pm
///
/// If the tenant has agreed in writing, rules 1, 3 and 4 don't apply. Rule 2 always applies.
struct ScheduleRoutineInspection {
    let properties: PropertyRepository
    let inspections: InspectionRepository
    let publicHolidays: NSWPublicHolidays
    let clock: DateProviding
    let widgetSnapshot: WidgetSnapshotWriting
    var calendar: Calendar = .sydney

    @discardableResult
    func execute(propertyID: UUID, scheduledAt: Date, noticeServedAt: Date, tenantConsentRecorded: Bool) throws -> RoutineInspection {
        if try properties.property(withID: propertyID) == nil {
            throw InspectionSchedulingError.propertyNotFound
        }
        if scheduledAt <= clock.now {
            throw InspectionSchedulingError.inspectionInThePast
        }

        if !tenantConsentRecorded {
            try checkNotice(noticeServedAt: noticeServedAt, scheduledAt: scheduledAt)
            try checkDay(scheduledAt)
            try checkStartTime(scheduledAt)
        }

        // this one is checked even when the tenant has agreed
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

    private func checkNotice(noticeServedAt: Date, scheduledAt: Date) throws {
        // compare whole days, not hours, so serving notice at 4pm still counts for that day
        let noticeDay = calendar.startOfDay(for: noticeServedAt)
        let inspectionDay = calendar.startOfDay(for: scheduledAt)
        let daysOfNotice = calendar.dateComponents([.day], from: noticeDay, to: inspectionDay).day!

        if daysOfNotice < RoutineInspectionRules.minimumNoticeDays {
            throw InspectionSchedulingError.insufficientNotice(earliestLawfulDate: earliestLawfulDate(noticeDay: noticeDay))
        }
    }

    // 7 days after the notice. If that lands on a Sunday or holiday, keep moving forward a day.
    private func earliestLawfulDate(noticeDay: Date) -> Date {
        var date = calendar.date(byAdding: .day, value: RoutineInspectionRules.minimumNoticeDays, to: noticeDay)!
        while isSunday(date) || publicHolidays.holidayName(on: date) != nil {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return date
    }

    private func checkDay(_ scheduledAt: Date) throws {
        if let holidayName = publicHolidays.holidayName(on: scheduledAt) {
            throw InspectionSchedulingError.sundayOrPublicHoliday(holidayName: holidayName)
        }
        if isSunday(scheduledAt) {
            throw InspectionSchedulingError.sundayOrPublicHoliday(holidayName: nil)
        }
    }

    private func checkStartTime(_ scheduledAt: Date) throws {
        let hour = calendar.component(.hour, from: scheduledAt)
        if !RoutineInspectionRules.permittedStartHours.contains(hour) {
            throw InspectionSchedulingError.outsidePermittedHours
        }
    }

    // The count is looked up from the database every time instead of being stored,
    // so cancelling an inspection frees up a spot straight away.
    private func checkAnnualLimit(propertyID: UUID, proposedDate: Date) throws {
        let windowStart = RoutineInspectionRules.annualWindowStart(endingAt: proposedDate, calendar: calendar)
        let counted = try inspections.inspectionsCountingTowardAnnualLimit(propertyID: propertyID, from: windowStart, through: proposedDate)

        if counted.count < RoutineInspectionRules.annualLimit {
            return
        }

        // Already at the limit. A new booking is allowed once the oldest one is more than
        // 12 months old. (The list is oldest first, so with exactly 4 it's the first one.)
        let oldest = counted[counted.count - RoutineInspectionRules.annualLimit]
        let nextAvailableDate = calendar.date(byAdding: .year, value: 1, to: oldest.scheduledAt)!
        throw InspectionSchedulingError.annualLimitReached(nextAvailableDate: nextAvailableDate)
    }

    private func isSunday(_ date: Date) -> Bool {
        return calendar.component(.weekday, from: date) == 1
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
            return "This tenant needs 7 days written notice. The earliest lawful date is \(earliestLawfulDate.inspectionDayText)."
        case .annualLimitReached:
            return "This property has already had 4 routine inspections in the 12 months before this date, which is the most NSW law allows."
        case .sundayOrPublicHoliday(let holidayName):
            if let holidayName = holidayName {
                return "Routine inspections can't be held on \(holidayName) because it's an NSW public holiday."
            }
            return "Routine inspections can't be held on a Sunday."
        case .outsidePermittedHours:
            return "Routine inspections have to start between 8:00 am and 8:00 pm."
        case .inspectionInThePast:
            return "That time has already passed."
        case .propertyNotFound:
            return "This property isn't in your portfolio any more."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .insufficientNotice(let earliestLawfulDate):
            return "Pick \(earliestLawfulDate.inspectionDayText) or later, or tick that the tenant has agreed in writing to an earlier time."
        case .annualLimitReached(let nextAvailableDate):
            return "You can book the next one after \(nextAvailableDate.inspectionTimeText) on \(nextAvailableDate.inspectionDayText), when the oldest of the 4 drops out of the 12 months."
        case .sundayOrPublicHoliday:
            return "Pick a day from Monday to Saturday that isn't a public holiday, or tick that the tenant has agreed in writing."
        case .outsidePermittedHours:
            return "Pick a start time from 8:00 am to 7:59 pm, or tick that the tenant has agreed in writing."
        case .inspectionInThePast:
            return "Pick a date and time later than now."
        case .propertyNotFound:
            return "Go back to the portfolio and pick the property again."
        }
    }
}
