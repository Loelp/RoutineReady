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
        // Start with notice served today and the inspection 8 days later at 10:00 am.
        let calendar = Calendar.sydney
        let eightDaysLater = calendar.date(byAdding: .day, value: 8, to: now)!
        scheduledAt = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: eightDaysLater)!
        noticeServedAt = now
    }

    /// Returns true if the inspection was booked, so the sheet can close.
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
