import Foundation
import Observation

@MainActor
@Observable
class ScheduleInspectionViewModel {
    var scheduledAt: Date
    var noticeServedAt: Date
    var tenantConsentRecorded = false
    var errorMessage: ErrorMessage?

    private let propertyID: UUID
    private let scheduleRoutineInspection: ScheduleRoutineInspection

    init(propertyID: UUID, scheduleRoutineInspection: ScheduleRoutineInspection, now: Date) {
        self.propertyID = propertyID
        self.scheduleRoutineInspection = scheduleRoutineInspection
        // default to notice today and the inspection 8 days later at 10am
        let calendar = Calendar.sydney
        let eightDaysLater = calendar.date(byAdding: .day, value: 8, to: now)!
        scheduledAt = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: eightDaysLater)!
        noticeServedAt = now
    }

    // returns true if it booked, so the sheet can close
    func book() -> Bool {
        do {
            try scheduleRoutineInspection.execute(
                propertyID: propertyID,
                scheduledAt: scheduledAt,
                noticeServedAt: noticeServedAt,
                tenantConsentRecorded: tenantConsentRecorded
            )
            return true
        } catch {
            errorMessage = ErrorMessage(error)
            return false
        }
    }
}
