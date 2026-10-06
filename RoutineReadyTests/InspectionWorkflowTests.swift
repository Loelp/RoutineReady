import XCTest
@testable import RoutineReady

// Tests for completing inspections, logging maintenance and importing shared photos.
// "Now" is Wed 7 Oct 2026, 9am (see InspectionFixture).
@MainActor
final class InspectionWorkflowTests: XCTestCase {
    private var fixture: InspectionFixture!

    override func setUp() {
        fixture = InspectionFixture()
    }

    func test_completing_requiresConditionSummary() throws {
        let inspection = try fixture.existingInspection(at: sydney(2026, 10, 7, 8, 30), status: .scheduled)

        XCTAssertThrowsError(try fixture.complete.execute(inspectionID: inspection.id, conditionSummary: "   ")) { error in
            XCTAssertEqual(error as? InspectionCompletionError, InspectionCompletionError.missingConditionSummary)
        }
    }

    func test_completing_savesSummary_andRefreshesWidget() throws {
        let inspection = try fixture.existingInspection(at: sydney(2026, 10, 7, 8, 30), status: .scheduled)

        let completed = try fixture.complete.execute(inspectionID: inspection.id, conditionSummary: "Clean and well kept.")

        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(completed.conditionSummary, "Clean and well kept.")
        XCTAssertEqual(completed.completedAt, fixture.clock.now)
        XCTAssertEqual(fixture.widgetSpy.refreshCount, 1)
    }

    func test_completing_rejectsCancelledInspection() throws {
        let inspection = try fixture.existingInspection(at: sydney(2026, 10, 7, 8, 30), status: .cancelled)

        XCTAssertThrowsError(try fixture.complete.execute(inspectionID: inspection.id, conditionSummary: "Clean and well kept.")) { error in
            XCTAssertEqual(error as? InspectionCompletionError, InspectionCompletionError.inspectionCancelled)
        }
    }

    func test_completing_rejectsInspectionBookedForALaterDay() throws {
        let inspection = try fixture.existingInspection(at: sydney(2026, 10, 8, 9, 0), status: .scheduled)

        XCTAssertThrowsError(try fixture.complete.execute(inspectionID: inspection.id, conditionSummary: "Clean and well kept.")) { error in
            XCTAssertEqual(error as? InspectionCompletionError, InspectionCompletionError.notYetDue)
        }
    }

    func test_loggingUrgentItem_requiresRoom() throws {
        let inspection = try fixture.existingInspection(at: sydney(2026, 10, 7, 8, 30), status: .scheduled)

        XCTAssertThrowsError(try fixture.logMaintenanceItem.execute(inspectionID: inspection.id, room: " ", description: "Exposed wiring", severity: .urgent)) { error in
            XCTAssertEqual(error as? MaintenanceLoggingError, MaintenanceLoggingError.urgentItemNeedsRoom)
        }
    }

    func test_loggingRoutineItem_withoutRoom_isAllowed() throws {
        let inspection = try fixture.existingInspection(at: sydney(2026, 10, 7, 8, 30), status: .scheduled)

        let item = try fixture.logMaintenanceItem.execute(inspectionID: inspection.id, room: "", description: "Faded paint on fence", severity: .cosmetic)

        XCTAssertEqual(try fixture.inspections.maintenanceItems(forInspectionID: inspection.id), [item])
    }

    func test_importingSharedPhotos_filesEachPhotoAsMaintenanceItem_andEmptiesInbox() throws {
        let inspection = try fixture.existingInspection(at: sydney(2026, 10, 7, 11, 15), status: .scheduled)
        try fixture.inbox.save(sharedRecord(for: inspection.id, note: "Mould above shower"))

        let result = try fixture.importSharedPhotos.execute()

        XCTAssertEqual(result.importedCount, 1)
        XCTAssertTrue(fixture.inbox.records.isEmpty)
        let item = try XCTUnwrap(fixture.inspections.maintenanceItems(forInspectionID: inspection.id).first)
        XCTAssertEqual(item.itemDescription, "Mould above shower")
        XCTAssertEqual(item.room, "Bathroom")
        XCTAssertEqual(item.photoFilename, "photo-1.jpg")
    }

    func test_importingSharedPhotos_toCancelledInspection_keepsRecordInInbox() throws {
        let inspection = try fixture.existingInspection(at: sydney(2026, 10, 7, 11, 15), status: .cancelled)
        let record = sharedRecord(for: inspection.id, note: "")
        try fixture.inbox.save(record)

        let result = try fixture.importSharedPhotos.execute()

        XCTAssertEqual(result.importedCount, 0)
        XCTAssertEqual(result.unfiled, [UnfiledSharedPhoto(record: record, reason: .inspectionNoLongerAvailable)])
        XCTAssertEqual(fixture.inbox.records, [record])
        XCTAssertTrue(fixture.inspections.maintenanceItems.isEmpty)
    }

    func test_reassigningUnfiledPhoto_filesItAgainstTheNewInspection() throws {
        let cancelled = try fixture.existingInspection(at: sydney(2026, 10, 7, 11, 15), status: .cancelled)
        let today = try fixture.existingInspection(at: sydney(2026, 10, 7, 14, 0), status: .scheduled)
        let record = sharedRecord(for: cancelled.id, note: "")
        try fixture.inbox.save(record)
        let reassign = ReassignSharedPhoto(inbox: fixture.inbox, importSharedPhotos: fixture.importSharedPhotos)

        let result = try reassign.execute(record: record, toInspectionID: today.id)

        XCTAssertEqual(result.importedCount, 1)
        XCTAssertEqual(try fixture.inspections.maintenanceItems(forInspectionID: today.id).first?.itemDescription,
                       ImportSharedPhotos.defaultDescription)
    }

    func test_propertyDetail_countsInspectionsUsedInLast12Months() throws {
        _ = try fixture.existingInspection(at: sydney(2025, 9, 1, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 3, 2, 10, 0))
        _ = try fixture.existingInspection(at: sydney(2026, 6, 1, 10, 0), status: .cancelled)
        _ = try fixture.existingInspection(at: sydney(2026, 9, 1, 10, 0))
        let load = LoadPropertyDetail(properties: fixture.properties, inspections: fixture.inspections, clock: fixture.clock)

        let detail = try load.execute(propertyID: fixture.property.id)

        XCTAssertEqual(detail.inspectionsUsedInLast12Months, 2)
        XCTAssertEqual(detail.inspectionHistory.count, 4)
    }

    private func sharedRecord(for inspectionID: UUID, note: String) -> SharedInboxRecord {
        SharedInboxRecord(id: UUID(), inspectionID: inspectionID, room: "Bathroom", note: note,
                          photoFilename: "photo-1.jpg", sharedAt: fixture.clock.now)
    }
}
