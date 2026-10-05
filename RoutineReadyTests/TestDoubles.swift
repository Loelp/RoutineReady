import XCTest
import Foundation
@testable import RoutineReady

struct FixedClock: DateProviding {
    var now: Date
}

final class WidgetSnapshotSpy: WidgetSnapshotWriting {
    private(set) var refreshCount = 0

    func refreshWidgetSnapshot() {
        refreshCount += 1
    }
}

struct StubPublicHolidays: NSWPublicHolidays {
    var holidays: [Date: String] = [:]

    func holidayName(on date: Date) -> String? {
        holidays[Calendar.sydney.startOfDay(for: date)]
    }
}

/// A date and time in Sydney, e.g. `sydney(2026, 10, 14, 10, 0)`.
func sydney(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    Calendar.sydney.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// A small portfolio and every use case wired to in-memory repositories.
/// "Now" is Wednesday 7 October 2026, 9:00 am in Sydney.
@MainActor
final class InspectionFixture {
    let property = Property(
        id: UUID(), address: "14 Rose St", suburb: "Yagoona",
        tenantName: "Mia Nguyen", landlordName: "Peter Haddad", tenancyStartDate: sydney(2025, 2, 1)
    )
    let clock = FixedClock(now: sydney(2026, 10, 7, 9, 0))
    let properties: InMemoryPropertyRepository
    let inspections = InMemoryInspectionRepository()
    let inbox = InMemorySharedPhotoInbox()
    let widgetSpy = WidgetSnapshotSpy()
    var holidays = StubPublicHolidays()

    init() {
        properties = InMemoryPropertyRepository([property])
    }

    var schedule: ScheduleRoutineInspection {
        ScheduleRoutineInspection(properties: properties, inspections: inspections, publicHolidays: holidays, clock: clock, widgetSnapshot: widgetSpy)
    }

    var complete: CompleteRoutineInspection {
        CompleteRoutineInspection(inspections: inspections, clock: clock, widgetSnapshot: widgetSpy)
    }

    var logMaintenanceItem: LogMaintenanceItem {
        LogMaintenanceItem(inspections: inspections, clock: clock, widgetSnapshot: widgetSpy)
    }

    var importSharedPhotos: ImportSharedPhotos {
        ImportSharedPhotos(inbox: inbox, logMaintenanceItem: logMaintenanceItem)
    }

    /// Adds an inspection directly to the repository, bypassing the booking rules.
    @discardableResult
    func existingInspection(at scheduledAt: Date, status: InspectionStatus = .completed) throws -> RoutineInspection {
        let inspection = RoutineInspection(
            id: UUID(), propertyID: property.id, scheduledAt: scheduledAt,
            noticeServedAt: Calendar.sydney.date(byAdding: .day, value: -8, to: scheduledAt)!,
            status: status, tenantConsentRecorded: false
        )
        try inspections.save(inspection)
        return inspection
    }

    func book(_ scheduledAt: Date, noticeServedAt: Date? = nil, tenantConsent: Bool = false) throws -> RoutineInspection {
        try schedule.execute(
            propertyID: property.id,
            scheduledAt: scheduledAt,
            noticeServedAt: noticeServedAt ?? clock.now,
            tenantConsentRecorded: tenantConsent
        )
    }
}

extension XCTestCase {
    /// Asserts that `body` throws exactly `expected`.
    func assertThrows<E: Error & Equatable>(_ expected: E, file: StaticString = #filePath, line: UInt = #line, _ body: () throws -> Void) {
        XCTAssertThrowsError(try body(), file: file, line: line) { error in
            XCTAssertEqual(error as? E, expected, file: file, line: line)
        }
    }
}
