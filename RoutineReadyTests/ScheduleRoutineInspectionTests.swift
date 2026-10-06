import XCTest
@testable import RoutineReady

// Tests for the booking rules. Unless a test says otherwise, notice is served "now" (Wed 7 Oct 2026, 9am).
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
        XCTAssertThrowsError(try fixture.book(sydney(2026, 10, 13, 10, 0))) { error in
            XCTAssertEqual(error as? InspectionSchedulingError, InspectionSchedulingError.insufficientNotice(earliestLawfulDate: sydney(2026, 10, 14)))
        }
        let message = InspectionSchedulingError.insufficientNotice(earliestLawfulDate: sydney(2026, 10, 14)).errorDescription
        XCTAssertEqual(message, "This tenant needs 7 days written notice. The earliest lawful date is Wed 14 Oct.")
    }

    func test_scheduling_allowsExactlySevenDaysNotice() throws {
        XCTAssertNoThrow(try fixture.book(sydney(2026, 10, 14, 8, 0)))
    }

    func test_scheduling_earliestLawfulDate_skipsSundaysAndPublicHolidays() {
        fixture.holidays.holidays[sydney(2026, 10, 19)] = "Test Holiday"
        // notice on Sun 11 Oct -> 7 days later is Sun 18 Oct, Mon 19 Oct is a holiday, so it should be Tue 20 Oct
        XCTAssertThrowsError(try fixture.book(sydney(2026, 10, 16, 10, 0), noticeServedAt: sydney(2026, 10, 11, 12, 0))) { error in
            XCTAssertEqual(error as? InspectionSchedulingError, InspectionSchedulingError.insufficientNotice(earliestLawfulDate: sydney(2026, 10, 20)))
        }
    }

    func test_scheduling_rejectsSunday() {
        XCTAssertThrowsError(try fixture.book(sydney(2026, 10, 18, 10, 0))) { error in
            XCTAssertEqual(error as? InspectionSchedulingError, InspectionSchedulingError.sundayOrPublicHoliday(holidayName: nil))
        }
    }

    func test_scheduling_rejectsPublicHoliday() {
        fixture.holidays.holidays[sydney(2026, 10, 16)] = "Test Holiday"

        XCTAssertThrowsError(try fixture.book(sydney(2026, 10, 16, 10, 0))) { error in
            XCTAssertEqual(error as? InspectionSchedulingError, InspectionSchedulingError.sundayOrPublicHoliday(holidayName: "Test Holiday"))
        }
    }

    func test_scheduling_allows7_59pmStart() {
        XCTAssertNoThrow(try fixture.book(sydney(2026, 10, 15, 19, 59)))
    }

    func test_scheduling_rejects8pmStart() {
        XCTAssertThrowsError(try fixture.book(sydney(2026, 10, 15, 20, 0))) { error in
            XCTAssertEqual(error as? InspectionSchedulingError, InspectionSchedulingError.outsidePermittedHours)
        }
    }

    func test_scheduling_rejectsTimeThatHasAlreadyPassed() {
        XCTAssertThrowsError(try fixture.book(sydney(2026, 10, 7, 8, 30), tenantConsent: true)) { error in
            XCTAssertEqual(error as? InspectionSchedulingError, InspectionSchedulingError.inspectionInThePast)
        }
    }

    func test_scheduling_rejectsFifthInspectionInRolling12Months() throws {
        _ = try fixture.existingInspection(at: sydney(2025, 11, 10, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 2, 9, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 5, 11, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 8, 10, 10, 0))

        XCTAssertThrowsError(try fixture.book(sydney(2026, 10, 15, 10, 0))) { error in
            XCTAssertEqual(error as? InspectionSchedulingError, InspectionSchedulingError.annualLimitReached(nextAvailableDate: sydney(2026, 11, 10, 10, 0)))
        }
    }

    func test_scheduling_annualLimitIsRolling_notCalendarYear() throws {
        // 4 inspections in the last 13 months, but the first one is more than 12 months before the new date
        _ = try fixture.existingInspection(at: sydney(2025, 9, 15, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 1, 12, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 4, 13, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 7, 13, 10, 0))

        XCTAssertNoThrow(try fixture.book(sydney(2026, 10, 15, 10, 0)))
    }

    func test_scheduling_ignoresCancelledInspections_whenCountingAnnualLimit() throws {
        _ = try fixture.existingInspection(at: sydney(2025, 11, 10, 10, 0), status: .cancelled)
        _ = try fixture.existingInspection(at: sydney(2026, 2, 9, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 5, 11, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 8, 10, 10, 0))

        XCTAssertNoThrow(try fixture.book(sydney(2026, 10, 15, 10, 0)))
    }

    func test_scheduling_withTenantConsent_allowsShortNotice_butStillEnforcesAnnualLimit() throws {
        // tomorrow at 8:30pm - not enough notice and too late, but the tenant has agreed so it's fine
        let agreed = try fixture.book(sydney(2026, 10, 8, 20, 30), tenantConsent: true)
        XCTAssertTrue(agreed.tenantConsentRecorded)

        _ = try fixture.existingInspection(at: sydney(2026, 2, 9, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 5, 11, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 8, 10, 10, 0))

        XCTAssertThrowsError(try fixture.book(sydney(2026, 10, 9, 10, 0), tenantConsent: true)) { error in
            XCTAssertEqual(error as? InspectionSchedulingError, InspectionSchedulingError.annualLimitReached(nextAvailableDate: sydney(2027, 2, 9, 10, 0)))
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
