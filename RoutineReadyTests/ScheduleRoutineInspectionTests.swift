import XCTest
@testable import RoutineReady

/// Notice is served "now": Wednesday 7 October 2026, 9:00 am.
@MainActor
final class ScheduleRoutineInspectionTests: XCTestCase {
    private var fixture: InspectionFixture!

    override func setUp() {
        fixture = InspectionFixture()
    }

    func test_scheduling_succeeds_withSevenDaysNotice_onAWeekdayMorning() throws {
        let inspection = try fixture.book(sydney(2026, 10, 15, 10, 30))

        XCTAssertEqual(inspection.status, .scheduled)
        XCTAssertEqual(try fixture.inspections.inspection(withID: inspection.id), inspection)
    }

    func test_scheduling_rejectsSixDaysNotice_andSuggestsEarliestLawfulDate() {
        assertThrows(InspectionSchedulingError.insufficientNotice(earliestLawfulDate: sydney(2026, 10, 14))) {
            _ = try fixture.book(sydney(2026, 10, 13, 10, 0))
        }
        let message = InspectionSchedulingError.insufficientNotice(earliestLawfulDate: sydney(2026, 10, 14)).errorDescription
        XCTAssertEqual(message, "This tenant needs 7 days written notice. The earliest lawful date is Wed 14 Oct.")
    }

    func test_scheduling_allowsExactlySevenDaysNotice() throws {
        XCTAssertNoThrow(try fixture.book(sydney(2026, 10, 14, 8, 0)))
    }

    func test_scheduling_earliestLawfulDate_skipsSundaysAndPublicHolidays() {
        fixture.holidays.holidays[sydney(2026, 10, 19)] = "Test Holiday"
        // Notice on Sun 11 Oct makes Sun 18 Oct the 7th day; Mon 19 Oct is a holiday, so Tue 20 Oct is the earliest.
        assertThrows(InspectionSchedulingError.insufficientNotice(earliestLawfulDate: sydney(2026, 10, 20))) {
            _ = try fixture.book(sydney(2026, 10, 16, 10, 0), noticeServedAt: sydney(2026, 10, 11, 12, 0))
        }
    }

    func test_scheduling_rejectsSunday() {
        assertThrows(InspectionSchedulingError.sundayOrPublicHoliday(holidayName: nil)) {
            _ = try fixture.book(sydney(2026, 10, 18, 10, 0))
        }
    }

    func test_scheduling_rejectsPublicHoliday() {
        fixture.holidays.holidays[sydney(2026, 10, 16)] = "Test Holiday"

        assertThrows(InspectionSchedulingError.sundayOrPublicHoliday(holidayName: "Test Holiday")) {
            _ = try fixture.book(sydney(2026, 10, 16, 10, 0))
        }
    }

    func test_scheduling_allows7_59pmStart() {
        XCTAssertNoThrow(try fixture.book(sydney(2026, 10, 15, 19, 59)))
    }

    func test_scheduling_rejects8pmStart() {
        assertThrows(InspectionSchedulingError.outsidePermittedHours) {
            _ = try fixture.book(sydney(2026, 10, 15, 20, 0))
        }
    }

    func test_scheduling_rejectsTimeThatHasAlreadyPassed() {
        assertThrows(InspectionSchedulingError.inspectionInThePast) {
            _ = try fixture.book(sydney(2026, 10, 7, 8, 30), tenantConsent: true)
        }
    }

    func test_scheduling_rejectsFifthInspectionInRolling12Months() throws {
        try fixture.existingInspection(at: sydney(2025, 11, 10, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 2, 9, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 5, 11, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 8, 10, 10, 0))

        assertThrows(InspectionSchedulingError.annualLimitReached(nextAvailableDate: sydney(2026, 11, 10, 10, 0))) {
            _ = try fixture.book(sydney(2026, 10, 15, 10, 0))
        }
    }

    func test_scheduling_annualLimitIsRolling_notCalendarYear() throws {
        // Four in the last 13 months, but the oldest is outside the 12 months before the proposed date.
        try fixture.existingInspection(at: sydney(2025, 9, 15, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 1, 12, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 4, 13, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 7, 13, 10, 0))

        XCTAssertNoThrow(try fixture.book(sydney(2026, 10, 15, 10, 0)))
    }

    func test_scheduling_ignoresCancelledInspections_whenCountingAnnualLimit() throws {
        try fixture.existingInspection(at: sydney(2025, 11, 10, 10, 0), status: .cancelled)
        try fixture.existingInspection(at: sydney(2026, 2, 9, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 5, 11, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 8, 10, 10, 0))

        XCTAssertNoThrow(try fixture.book(sydney(2026, 10, 15, 10, 0)))
    }

    func test_scheduling_withTenantConsent_allowsShortNotice_butStillEnforcesAnnualLimit() throws {
        // Tomorrow at 8:30 pm: short notice and outside hours, but the tenant agreed in writing.
        let agreed = try fixture.book(sydney(2026, 10, 8, 20, 30), tenantConsent: true)
        XCTAssertTrue(agreed.tenantConsentRecorded)

        try fixture.existingInspection(at: sydney(2026, 2, 9, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 5, 11, 10, 0))
        try fixture.existingInspection(at: sydney(2026, 8, 10, 10, 0))

        assertThrows(InspectionSchedulingError.annualLimitReached(nextAvailableDate: sydney(2027, 2, 9, 10, 0))) {
            _ = try fixture.book(sydney(2026, 10, 9, 10, 0), tenantConsent: true)
        }
    }

    func test_successfulSchedule_refreshesWidgetSnapshot() throws {
        _ = try fixture.book(sydney(2026, 10, 15, 10, 30))

        XCTAssertEqual(fixture.widgetSpy.refreshCount, 1)
    }

    func test_rejectedSchedule_leavesWidgetSnapshotAlone() {
        _ = try? fixture.book(sydney(2026, 10, 18, 10, 0))

        XCTAssertEqual(fixture.widgetSpy.refreshCount, 0)
    }

    func test_nswCalendar_knowsLabourDay2026_andIgnoresOrdinaryDays() {
        let holidays = GazettedNSWPublicHolidays()

        XCTAssertEqual(holidays.holidayName(on: sydney(2026, 10, 5, 10, 0)), "Labour Day")
        XCTAssertNil(holidays.holidayName(on: sydney(2026, 10, 6, 10, 0)))
    }
}
